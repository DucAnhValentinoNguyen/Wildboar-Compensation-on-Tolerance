run_eda<-function(prepared) {
  a<-readRDS(prepared);d<-a$data;x<-a$input;raw<-a$raw
  nums<-names(d)[vapply(d,is.numeric,logical(1))]
  profile<-do.call(rbind,lapply(nums,function(v){y<-d[[v]];q<-quantile(y,c(0,.25,.5,.75,1),na.rm=TRUE);data.frame(variable=v,n=sum(!is.na(y)),missing=sum(is.na(y)),mean=mean(y,na.rm=TRUE),sd=sd(y,na.rm=TRUE),min=q[1],q25=q[2],median=q[3],q75=q[4],max=q[5])}))
  save_table(profile,"eda_numeric")
  categorical<-do.call(rbind,lapply(names(d),function(v){y<-d[[v]];if(length(unique(y))<=15)data.frame(variable=v,value=names(table(y,useNA="ifany")),n=as.vector(table(y,useNA="ifany")))else NULL}))
  save_table(categorical,"eda_categories")
  groups<-do.call(rbind,lapply(c("county","application","np"),function(g)do.call(rbind,lapply(nums,function(v)do.call(rbind,lapply(unique(d[[g]]),function(l){y<-d[[v]][d[[g]]==l];data.frame(grouping=g,group=as.character(l),variable=v,n=sum(!is.na(y)),mean=mean(y,na.rm=TRUE),median=median(y,na.rm=TRUE),sd=sd(y,na.rm=TRUE))}))))))
  save_table(groups,"eda_group_profiles")
  balance<-do.call(rbind,lapply(setdiff(nums,c("ID","application")),function(v){y0<-d[[v]][d$application==0];y1<-d[[v]][d$application==1];data.frame(variable=v,smd=(mean(y1,na.rm=TRUE)-mean(y0,na.rm=TRUE))/sqrt((var(y1,na.rm=TRUE)+var(y0,na.rm=TRUE))/2))}))
  save_table(balance,"application_balance")
  items<-c(TOLS,"ic1","word1","word2","word3","benefit","report_count","info_count","conflict_wb","conflict_all")
  for(method in c("pearson","spearman")){cc<-cor(d[items],use="pairwise.complete.obs",method=method);save_table(data.frame(variable=rownames(cc),cc),paste0("correlation_",method))}
  freq<-reshape(d[c("ID","application",TOLS)],varying=TOLS,v.names="response",timevar="item",times=TOLS,direction="long")
  p<-ggplot2::ggplot(freq,ggplot2::aes(factor(response),fill=factor(application)))+ggplot2::geom_bar(position="dodge")+ggplot2::facet_wrap(~item,scales="free_y")+ggplot2::labs(x="Stored response: higher = greater tolerance / less safety concern",y="Respondents",fill="Applied",title="Four distinct tolerance questions")+ggplot2::theme_minimal(base_size=12)
  plot_save("tolerance_distributions",p)
  plot_save("application_by_county",ggplot2::ggplot(d,ggplot2::aes(county,fill=factor(application)))+ggplot2::geom_bar(position="fill")+ggplot2::labs(y="Proportion",x=NULL,fill="Applied",title="Application rates differ strongly by county")+ggplot2::theme_minimal(base_size=13))
  plot_save("balance",ggplot2::ggplot(subset(balance,is.finite(smd)),ggplot2::aes(smd,reorder(variable,smd)))+ggplot2::geom_point()+ggplot2::geom_vline(xintercept=0,lty=2)+ggplot2::labs(x="Unadjusted standardized mean difference",y=NULL,title="Applicants and non-applicants differ on observed characteristics")+ggplot2::theme_minimal(base_size=10),9,9)
  for(q in c("Q10","Q18","Q23","Q27","Q28","Q29","Q38")){s<-as.character(raw[[q]]);terms<-unlist(strsplit(s[!is.na(s)],"[,，]"));tb<-sort(table(trimws(terms)),decreasing=TRUE);save_table(data.frame(response=names(tb),n=as.vector(tb)),paste0("raw_",q,"_frequencies"))}
  words<-unlist(raw[paste0("Q35_",1:3)],use.names=FALSE);tb<-sort(table(trimws(words[!is.na(words)])),decreasing=TRUE);save_table(data.frame(word=names(tb),n=as.vector(tb)),"descriptive_words")
  crops<-names(x)[grepl("^Q10_",names(x))];save_table(data.frame(crop=crops,households=sapply(x[crops],function(v)sum(v>0)),total_recorded_area=sapply(x[crops],sum),median_recorded_area=sapply(x[crops],median)),"crop_portfolio")
  metrics<-data.frame(metric=c("respondents","applicants","counties","townships","villages","inside_park","missing_village","invalid_minimum_ratio","invalid_desired_ratio","damage_exceeds_area","prevention_nonusers","alpha_four","alpha_three"),value=c(nrow(d),sum(d$application),nlevels(d$county),length(unique(d$township)),length(unique(d$village)),sum(d$np),sum(is.na(x$Q1_Village)),sum(d$minimum_ratio_flag),sum(d$desired_ratio_flag),sum(d$damage_exceeds_area),sum(d$prevention_used==0),psych::alpha(d[TOLS],check.keys=FALSE,warnings=FALSE)$total$raw_alpha,psych::alpha(d[c("tol1","tol2","tol4")],check.keys=FALSE,warnings=FALSE)$total$raw_alpha))
  save_table(metrics,"sample_metrics");log_event("eda","success","All derived variables and raw question families profiled");file.path(OUT,"tables/eda_numeric.csv")
}
