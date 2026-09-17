prepare_data <- function() {
  source(file.path(ROOT,"src/fresh/common.R"))
  p<-file.path(ROOT,"data/3_Data.xlsx")
  x<-as.data.frame(readxl::read_excel(p,sheet="Input Data"))
  for(v in setdiff(names(x),c("Q1_County","Q1_Township","Q1_Village")))x[[v]]<-numeric_safely(x[[v]])
  rr<-as.data.frame(readxl::read_excel(p,sheet="Raw data",.name_repair="unique"))
  labels<-as.character(rr[1,]);raw<-rr[-1,]; raw$ID<-numeric_safely(raw$ID)
  stopifnot(!anyDuplicated(x$ID),!anyDuplicated(raw$ID),setequal(x$ID,raw$ID))
  raw<-raw[match(x$ID,raw$ID),];stopifnot(identical(as.numeric(x$ID),raw$ID))
  raw_inventory<-data.frame(field=names(raw),label=labels,missing=vapply(raw,function(v)sum(is.na(v)|trimws(as.character(v))==""),numeric(1)),unique=vapply(raw,function(v)length(unique(na.omit(v))),integer(1)))
  save_table(raw_inventory,"raw_field_inventory")
  changes<-list(); record<-function(field,old,new,reason) {
    changed<-xor(is.na(old),is.na(new))|(!is.na(old)&!is.na(new)&as.character(old)!=as.character(new))
    if(any(changed)) changes[[length(changes)+1]]<<-data.frame(ID=x$ID[changed],field=field,original=as.character(old[changed]),derived=as.character(new[changed]),reason=reason)
  }
  d<-data.frame(ID=x$ID,county=factor(x$Q1_County),township=paste(x$Q1_County,x$Q1_Township,sep="/"),
    village=paste(x$Q1_County,x$Q1_Township,ifelse(is.na(x$Q1_Village),paste0("missing_",x$ID),x$Q1_Village),sep="/"),
    application=x$CE0,np=x$Q3_InNP,age=x$Q5_Age,gender=x$Q4_Gender,education=factor(x$Q6_Education),household_size=x$Q7_HouseholdPop,
    income=x$Q8_AnnualIncome,agri_share=x$Q9_AgriProportion/100,area=x$Q11_TotalArea,livestock=x$Q13_TotalLivestock,assets=x$Q14_HouseholdAsset,
    damage=x$TC1_DamagedArea,loss=x$TC2_EconomicLoss,benefit=x$IB,ic1=x$IC1,info_count=x$PS2,
    minimum_ratio=x$CA1,desired_ratio=x$CA2,insurance_wtp=x$CA3,timeliness=x$CE1,satisfaction=x$CE2)
  map<-c("非常不同意"=1,"不同意"=2,"一般"=3,"同意"=4,"非常同意"=5)
  for(i in 1:4) {
    col<-c("Tol1_5","Tol2_1","Tol3_1","Tol4_5")[i];q<-c("Q30_5","Q30_4","Q30_3","Q30_2")[i]
    expected<-unname(map[as.character(raw[[q]])]);if(i%in%c(2,3))expected<-6-expected
    stopifnot(all(x[[col]][!is.na(expected)]==expected[!is.na(expected)]))
    d[[paste0("tol",i)]]<-x[[col]];d[[paste0("tol",i)]][is.na(raw[[q]])]<-NA
    record(paste0("tol",i),x[[col]],d[[paste0("tol",i)]],"Restore raw nonresponse; stored orientation retained")
  }
  for(i in 1:3){v<-x[[paste0("IC2_",i)]];v[v==0]<-NA;d[[paste0("word",i)]]<-v;record(paste0("word",i),x[[paste0("IC2_",i)]],v,"Zero encodes missing descriptive word")}
  d$word_count<-rowSums(!is.na(d[paste0("word",1:3)]));d$word_mean<-mean_available(d[paste0("word",1:3)])
  d$ic<-mean_available(data.frame(z(d$ic1),z(d$word_mean)))
  d$conflict_wb<-rowMeans(x[paste0("CP_WB",1:4)])
  d$conflict_all<-rowMeans(x[paste0("CP_A",1:3)])
  institutions<-c("保险公司","村两委","林业部门","狩猎队")
  reporting<-as.character(raw$Q17)
  for(j in seq_along(institutions))d[[paste0("report_",j)]]<-ifelse(is.na(reporting),NA,as.integer(grepl(institutions[j],reporting,fixed=TRUE)))
  d$report_count<-rowSums(d[paste0("report_",1:4)])
  d$report_contradiction<-!is.na(reporting)&grepl("不上报",reporting,fixed=TRUE)&d$report_count>0
  record("report_count",x$PS1,d$report_count,"Reconstructed increasing count from raw choices; replaces reverse-direction PS1")
  for(v in c("minimum_ratio","desired_ratio")) {d[[paste0(v,"_original")]]<-d[[v]];d[[paste0(v,"_flag")]]<-d[[v]]>1|d[[v]]<0;old<-d[[v]];d[[v]][d[[paste0(v,"_flag")]]]<-NA;record(v,old,d[[v]],"Unresolved percentage outside 0..100%; retained in original field")}
  for(v in c("timeliness","satisfaction")){q<-if(v=="timeliness")"Q14" else "Q15";old<-d[[v]];d[[v]][is.na(raw[[q]])|d$application==0]<-NA;record(v,old,d[[v]],"Restore raw/structural nonresponse")}
  for(j in 1:7){ix<-which(labels==paste0("PE_",LETTERS[j]));v<-if(length(ix))numeric_safely(raw[[ix[1]]]) else rep(NA,nrow(d));d[[paste0("prevention_",LETTERS[j])]]<-v
    # Q36 method order in raw differs from translated codebook; retain raw labels.
    d[[paste0("prevention_cost_",j)]]<-numeric_safely(raw[[paste0("Q36_",j,"_TEXT")]])
  }
  pe<-d[paste0("prevention_",LETTERS[1:7])]
  d$prevention_n<-rowSums(pe>0,na.rm=TRUE);d$prevention_used<-as.integer(d$prevention_n>0)
  pe[pe==0]<-NA;d$prevention_eff<-mean_available(pe);d$prevention_eff0<-ifelse(d$prevention_used==0,0,d$prevention_eff)
  record("prevention_eff",x$PE,d$prevention_eff,"Mean of used preventive methods; non-use is undefined effectiveness")
  for(v in c("income","area","livestock","assets","damage","loss"))d[[paste0("log_",v)]]<-log1p(d[[v]])
  d$tolerance3<-rowMeans(d[c("tol1","tol2","tol4")]);d$tolerance4<-rowMeans(d[TOLS])
  d$damage_exceeds_area<-d$damage>d$area
  d$damage_share<-ifelse(d$area>0,d$damage/d$area,NA)
  d$loss_income_share<-ifelse(d$income>0,d$loss/d$income,NA)
  # Search deterministic village allocations for a balanced internal validation split.
  g<-unique(d$village);best<-Inf;allocation<-NULL;set.seed(SEED)
  for(k in 1:2000){dev<-sample(g,round(length(g)/2));a<-d$village%in%dev
    counts<-table(d$county,d$application);devcounts<-table(factor(d$county[a],levels=levels(d$county)),factor(d$application[a],levels=0:1))
    score<-sum(((devcounts-.5*counts)/pmax(counts,1))^2)
    if(score<best){best<-score;allocation<-a}}
  d$partition<-ifelse(allocation,"development","validation")
  stopifnot(length(intersect(d$village[allocation],d$village[!allocation]))==0,all(is.na(d$timeliness[d$application==0])))
  dir.create(file.path(ROOT,"data/derived"),showWarnings=FALSE)
  write.csv(d,file.path(ROOT,"data/derived/analysis.csv"),row.names=FALSE,na="")
  write.csv(do.call(rbind,changes),file.path(ROOT,"data/derived/transformation_log.csv"),row.names=FALSE,na="")
  save_model(list(data=d,input=x,raw=raw,labels=labels),"prepared")
  save_table(as.data.frame(table(d$county,d$application,d$partition)),"split_balance")
  save_table(data.frame(field=names(d),class=vapply(d,function(v)class(v)[1],character(1)),missing=vapply(d,function(v)sum(is.na(v)),integer(1))),"derived_dictionary")
  log_event("prepare","success",paste(nrow(d),"respondents; village-disjoint validation split"));file.path(OUT,"models/prepared.rds")
}
