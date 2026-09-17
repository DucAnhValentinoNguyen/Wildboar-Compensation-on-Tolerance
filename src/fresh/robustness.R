run_robustness<-function(prepared){
  d<-readRDS(prepared)$data;rows<-list();seen<-new.env(parent=emptyenv());fail<-list()
  # Each outcome/adjustment family is displayed separately; no arbitrary all-subset search.
  sets<-list(none=character(),background=BG,resources=c(BG,RES),conflict=c(BG,RES,"conflict_wb","conflict_all"),explanatory=c(BG,RES,EXPL))
  for(y in c(TOLS,"tolerance3","tolerance4"))for(s in names(sets))for(transform in c("log","raw"))for(rule in c("retain","exclude_extreme_loss","exclude_reporting_conflict"))for(miss in c("complete","median_mode_sensitivity")){
    dd<-d;ctrl<-sets[[s]]
    if(transform=="raw")ctrl<-sub("^log_","",ctrl)
    if(rule=="exclude_extreme_loss")dd<-dd[dd$loss<=quantile(d$loss,.99),]
    if(rule=="exclude_reporting_conflict")dd<-dd[!dd$report_contradiction,]
    vars<-unique(c(y,"application",ctrl,"township","village"));dd<-dd[,vars]
    if(miss=="median_mode_sensitivity")for(v in ctrl){if(is.numeric(dd[[v]]))dd[[v]][is.na(dd[[v]])]<-median(dd[[v]],na.rm=TRUE)else if(anyNA(dd[[v]]))dd[[v]][is.na(dd[[v]])]<-names(which.max(table(dd[[v]])))}
    dd<-dd[complete.cases(dd),];f<-reformulate(c("application",ctrl),y)
    # Deduplicate exact model inputs before fitting; uncertainty variants remain explicit.
    key<-digest::digest(list(outcome=y,formula=deparse(f),data=dd));if(exists(key,seen,inherits=FALSE))next;assign(key,TRUE,seen)
    dd[[y]]<-z(dd[[y]]);fit<-attempt("specification",lm(f,dd));if(is.null(fit)){fail[[length(fail)+1]]<-data.frame(outcome=y,adjustment=s,transform=transform,rule=rule,missing=miss);next}
    for(g in c("township","village")){r<-attempt("spec_cluster",cluster_coef(fit,dd,group=g));if(is.null(r))next;r$outcome<-y;r$adjustment<-s;r$transform<-transform;r$rule<-rule;r$missing<-miss;r$clustering<-g;rows[[length(rows)+1]]<-r}
  }
  rr<-do.call(rbind,rows);save_table(rr,"specification_curve");if(length(fail))save_table(do.call(rbind,fail),"specification_failures")
  rr$rank<-ave(rr$estimate,rr$outcome,FUN=rank)
  plot_save("specification_curve",ggplot2::ggplot(rr,ggplot2::aes(rank,estimate,color=adjustment))+ggplot2::geom_point(alpha=.6,size=1)+ggplot2::facet_wrap(~outcome,scales="free_x")+ggplot2::geom_hline(yintercept=0,lty=2)+ggplot2::labs(x="Specification rank within outcome",y="Standardized association",title="Reasonable choices can answer different questions")+ggplot2::theme_minimal(base_size=11),11,7)
  sumr<-do.call(rbind,lapply(split(rr,interaction(rr$outcome,rr$adjustment,drop=TRUE)),function(v)data.frame(outcome=v$outcome[1],adjustment=v$adjustment[1],specifications=nrow(v),min=min(v$estimate),median=median(v$estimate),max=max(v$estimate),negative_fraction=mean(v$estimate<0))))
  save_table(sumr,"specification_summary")
  vars<-c("tolerance3","application",BG,RES,"township","village");dd<-d[complete.cases(d[vars]),];dd$tolerance3<-z(dd$tolerance3)
  jk<-do.call(rbind,lapply(unique(dd$township),function(g){a<-dd[dd$township!=g,];r<-cluster_coef(lm(reformulate(c("application",BG,RES),"tolerance3"),a),a);r$left_out<-g;r}))
  save_table(jk,"leave_one_township_out")
  ct<-do.call(rbind,lapply(levels(dd$county),function(ct){a<-droplevels(dd[dd$county==ct,]);r<-cluster_coef(lm(reformulate(c("application",setdiff(BG,"county"),RES),"tolerance3"),a),a);r$county<-ct;r}))
  save_table(ct,"county_specific_associations")
  # Equivalent observed-scale interaction is interpretable without PLS invariance.
  ii<-d[complete.cases(d[c("tolerance3","application",BG,RES,"ic","township")]),];ii$ic<-z(ii$ic)
  f<-lm(reformulate(c("application*ic",BG,RES),"tolerance3"),ii);r<-cluster_coef(f,ii,term="application:ic");r$f2<-(summary(f)$r.squared-summary(update(f,.~.-application:ic))$r.squared)/(1-summary(f)$r.squared);save_table(r,"observed_interaction")
  file.path(OUT,"tables/specification_summary.csv")
}
