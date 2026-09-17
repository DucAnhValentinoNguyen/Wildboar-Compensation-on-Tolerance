run_secondary<-function(prepared){
  a<-readRDS(prepared);d<-a$data;raw<-a$raw;x<-a$input;rows<-list();status<-list()
  lm_result<-function(label,formula,dd,term="application",family=NULL){
    needed<-unique(c(all.vars(formula),"township"));dd<-dd[complete.cases(dd[needed]),];if(nrow(dd)<30){status[[length(status)+1]]<<-data.frame(analysis=label,status="insufficient complete observations",n=nrow(dd));return(NULL)}
    fit<-attempt(label,if(is.null(family))lm(formula,dd)else glm(formula,dd,family=family))
    if(is.null(fit))return(NULL)
    r<-attempt(paste(label,"cluster"),cluster_coef(fit,dd,term=term));if(!is.null(r)){r$analysis<-label;r$scale<-if(is.null(family))"outcome units"else"log odds";rows[[length(rows)+1]]<<-r}
    save_model(fit,paste0("secondary_",label));invisible(fit)
  }
  lm_result("application_selection",reformulate(c(BG,RES,"conflict_wb","log_loss"),"application"),d,term="log_loss",family=binomial())
  app<-d[d$application==1,];lm_result("applicant_timeliness",reformulate(c("timeliness",BG,"log_loss"),"tolerance3"),app,"timeliness")
  lm_result("applicant_satisfaction",reformulate(c("satisfaction",BG,"log_loss"),"tolerance3"),app,"satisfaction")
  lm_result("applicant_both_experiences",reformulate(c("timeliness","satisfaction",BG,"log_loss"),"tolerance3"),app,"satisfaction")
  lm_result("livelihood_dependence",reformulate(c("application",BG,RES,"log_loss"),"tolerance3"),d,"agri_share")
  lm_result("damage_burden",reformulate(c("application",BG,RES,"damage_share"),"tolerance3"),d,"damage_share")
  lm_result("income_loss_burden",reformulate(c("application",BG,"log_income","loss_income_share"),"tolerance3"),d,"loss_income_share")
  lm_result("prevention_adoption",reformulate(c("application",BG,"conflict_wb","log_loss"),"prevention_used"),d,family=binomial())
  users<-d[d$prevention_used==1,];lm_result("prevention_effectiveness_users",reformulate(c("application",BG,"prevention_eff","log_loss"),"tolerance3"),users,"prevention_eff")
  d$positive_wtp<-as.integer(d$insurance_wtp>0);lm_result("insurance_positive_wtp",reformulate(c("application",BG,"log_income","agri_share"),"positive_wtp"),d,family=binomial())
  d$log_wtp<-log(d$insurance_wtp);lm_result("insurance_positive_amount",reformulate(c("application",BG,"log_income","agri_share"),"log_wtp"),d[d$positive_wtp==1,])
  for(y in c("minimum_ratio","desired_ratio")){lm_result(paste0(y,"_validated"),reformulate(c("application",BG),y),d);dd<-d;dd[[y]]<-dd[[paste0(y,"_original")]];lm_result(paste0(y,"_retain_flagged"),reformulate(c("application",BG),y),dd)}
  lm_result("reporting_contacts",reformulate(c("application",BG,"report_count","info_count","log_loss"),"tolerance3"),d,"report_count")
  lm_result("information_channels",reformulate(c("application",BG,"report_count","info_count","log_loss"),"tolerance3"),d,"info_count")
  rr<-do.call(rbind,rows);rr$p_BH_exploratory<-p.adjust(rr$p,"BH");save_table(rr,"secondary_associations")
  pe<-do.call(rbind,lapply(1:7,function(j){v<-d[[paste0("prevention_",LETTERS[j])]];cost<-d[[paste0("prevention_cost_",j)]];data.frame(method=LETTERS[j],raw_question=as.character(a$labels[match(paste0("Q36_",j),names(raw))]),users=sum(v>0,na.rm=TRUE),nonusers=sum(v==0,na.rm=TRUE),mean_effectiveness_users=mean(v[v>0],na.rm=TRUE),recorded_cost_n=sum(!is.na(cost)),median_recorded_cost=median(cost,na.rm=TRUE))}))
  save_table(pe,"prevention_methods")
  payout_cols<-c("Q15_1_TEXT","Q15_2_TEXT","Q15_3_TEXT");payout<-sapply(raw[payout_cols],function(v){s<-trimws(as.character(v));valid<-grepl("^[0-9]+(\\.[0-9]+)?$",s);out<-rep(NA_real_,length(s));out[valid]<-as.numeric(s[valid]);out})
  d$payout<-apply(payout,1,function(v)if(sum(!is.na(v))==1)sum(v,na.rm=TRUE)else NA_real_)
  save_table(data.frame(metric=c("applicants","numeric_unambiguous_payouts_applicants","median_available_payout","timeliness_observed","satisfaction_observed","zero_income","loss_income_undefined"),value=c(sum(d$application),sum(!is.na(d$payout)&d$application==1),median(d$payout[d$application==1],na.rm=TRUE),sum(!is.na(d$timeliness)),sum(!is.na(d$satisfaction)),sum(d$income==0),sum(is.na(d$loss_income_share)))),"secondary_coverage")
  # Crop-specific losses retain the original seven question components and monetary units.
  crop_loss<-do.call(rbind,lapply(1:7,function(j){v<-numeric_safely(raw[[paste0("Q25_",j)]]);data.frame(field=paste0("Q25_",j),label=a$labels[match(paste0("Q25_",j),names(raw))],n=sum(!is.na(v)),positive=sum(v>0,na.rm=TRUE),median=median(v,na.rm=TRUE),total=sum(v,na.rm=TRUE))}))
  save_table(crop_loss,"crop_specific_losses")
  save_table(data.frame(question=c("payout_loss_ratio","word_themes","causal_effectiveness"),status=c("Not estimated: reference periods and payout coverage not verified","Original frequencies supplied; thematic interpretation requires Chinese-language human review","Prevention is self-selected; conditional associations only")),"secondary_limitations")
  file.path(OUT,"tables/secondary_associations.csv")
}
