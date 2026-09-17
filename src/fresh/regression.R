run_regression<-function(prepared) {
  d<-readRDS(prepared)$data;rows<-list();probs<-list();nominal<-list();fits<-list()
  sets<-list(unadjusted=character(),background=BG,resources=c(BG,RES),explanatory=c(BG,RES,EXPL))
  for(y in TOLS)for(s in names(sets)){
    vars<-unique(c(y,"application",sets[[s]],"township","village"));dd<-d[complete.cases(d[vars]),vars];dd[[y]]<-ordered(dd[[y]])
    f<-reformulate(c("application",sets[[s]]),response=y)
    fit<-attempt(paste("ordinal",y,s),MASS::polr(f,data=dd,Hess=TRUE,method="logistic"))
    if(!is.null(fit)){
      fits[[paste(y,s,sep="_")]]<-fit;r<-attempt("ordinal_cluster",cluster_coef(fit,dd));if(!is.null(r)){r$outcome<-y;r$adjustment<-s;r$model<-"cumulative_logit";rows[[length(rows)+1]]<-r}
      a<-dd;b<-dd;a$application<-0;b$application<-1
      p0<-predict(fit,a,type="probs");p1<-predict(fit,b,type="probs")
      probs[[length(probs)+1]]<-data.frame(outcome=y,adjustment=s,category=colnames(p0),p_no_application=colMeans(p0),p_application=colMeans(p1),difference=colMeans(p1-p0))
    }
    if(s=="background"){
      cl<-attempt(paste("clm",y),do.call(ordinal::clm,list(formula=f,data=dd)));nt<-if(!is.null(cl))attempt("proportional_odds",ordinal::nominal_test(cl,scope=~application)) else NULL
      if(!is.null(nt)){nt<-as.data.frame(nt);nt$term<-rownames(nt);nt$outcome<-y;nominal[[length(nominal)+1]]<-nt
        # Application-specific nonparallel alternative is fixed in advance; do not change all slopes on p-values.
        alt<-attempt(paste("partial_PO",y),do.call(ordinal::clm,list(formula=f,nominal=~application,data=dd)));fits[[paste0(y,"_partial_PO")]]<-alt
        if(!is.null(alt)){pa<-summary(alt)$coefficients;save_table(data.frame(term=rownames(pa),pa),paste0("partial_PO_",y))}
      }
    }
  }
  if(length(rows)){rr<-do.call(rbind,rows);rr$p_holm<-ave(rr$p,rr$adjustment,FUN=function(p)p.adjust(p,"holm"));rr$odds_ratio<-exp(rr$estimate);save_table(rr,"ordinal_associations")}
  if(length(probs))save_table(do.call(rbind,probs),"ordinal_probabilities")
  if(length(nominal))save_table(do.call(rbind,nominal),"proportional_odds_tests")
  rr<-list()
  for(y in c("tolerance3","tolerance4"))for(s in names(sets)){
    vars<-unique(c(y,"application",sets[[s]],"township","village"));dd<-d[complete.cases(d[vars]),vars];dd[[y]]<-z(dd[[y]])
    fit<-lm(reformulate(c("application",sets[[s]]),y),dd);fits[[paste(y,s,sep="_")]]<-fit
    for(g in c("township","village")){r<-cluster_coef(fit,dd,group=g);r$outcome<-y;r$adjustment<-s;r$covariance<-g;rr[[length(rr)+1]]<-r}
    if(s=="resources"){
      gam<-attempt(paste("GAM",y),mgcv::gam(as.formula(paste(y,"~ application + county + np + gender + education + household_size + s(age,k=5) + s(log_income,k=5) + agri_share + s(log_area,k=5) + log_livestock + log_assets")),data=dd,method="REML"));fits[[paste0(y,"_gam")]]<-gam
      if(!is.null(gam)){sm<-summary(gam);save_table(data.frame(term=rownames(sm$p.table),sm$p.table),paste0("gam_",y,"_parametric"));save_table(data.frame(term=rownames(sm$s.table),sm$s.table),paste0("gam_",y,"_smooths"))}
    }
  }
  rr<-do.call(rbind,rr);save_table(rr,"score_associations")
  plot_save("primary_ordinal",ggplot2::ggplot(subset(do.call(rbind,rows),adjustment=="background"),ggplot2::aes(estimate,outcome,xmin=low,xmax=high))+ggplot2::geom_pointrange()+ggplot2::geom_vline(xintercept=0,lty=2)+ggplot2::labs(x="Application log odds ratio (95% township-clustered CI)",y=NULL,title="Item-level associations need not share the same direction")+ggplot2::theme_minimal(base_size=12))
  plot_save("score_associations",ggplot2::ggplot(subset(rr,covariance=="township"),ggplot2::aes(estimate,adjustment,xmin=low,xmax=high,color=outcome))+ggplot2::geom_pointrange(position=ggplot2::position_dodge(width=.4))+ggplot2::geom_vline(xintercept=0,lty=2)+ggplot2::labs(x="Application contrast in outcome SD",y=NULL,title="Composite associations depend on outcome and adjustment")+ggplot2::theme_minimal(base_size=12))
  save_model(fits,"regression_fits");file.path(OUT,"models/regression_fits.rds")
}
