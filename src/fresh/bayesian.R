run_bayesian<-function(prepared) {
  d<-readRDS(prepared)$data;dd<-d[complete.cases(d[c(TOLS,BG,"application","township")]),]
  dd$age<-z(dd$age);dd$household_size<-z(dd$household_size)
  rows<-list();diagnostics<-list();fit<-NULL
  for(y in TOLS){dd$response<-ordered(dd[[y]],levels=1:5)
    path<-file.path(OUT,"models",paste0("bayes_",y))
    if(file.exists(paste0(path,".rds"))) f<-readRDS(paste0(path,".rds")) else {
      f<-attempt(paste0("Bayes_",y),brms::brm(response~application+county+np+age+gender+education+household_size+(1|township),data=dd,
        family=brms::cumulative("logit"),prior=c(brms::prior(normal(0,1),class="b"),brms::prior(exponential(1),class="sd")),
        chains=4,cores=4,iter=2000,warmup=1000,seed=SEED,control=list(adapt_delta=.99,max_treedepth=12),
        refresh=0,file=path,save_pars=brms::save_pars(all=TRUE)))
    }
    if(is.null(f))next
    sm<-posterior::summarise_draws(posterior::as_draws_array(f));np<-brms::nuts_params(f);div<-sum(np$Value[np$Parameter=="divergent__"])
    good<-max(sm$rhat,na.rm=TRUE)<=1.01&&min(sm$ess_bulk,na.rm=TRUE)>=400&&min(sm$ess_tail,na.rm=TRUE)>=400&&div==0
    diagnostics[[length(diagnostics)+1]]<-data.frame(outcome=y,max_rhat=max(sm$rhat,na.rm=TRUE),min_bulk_ess=min(sm$ess_bulk,na.rm=TRUE),min_tail_ess=min(sm$ess_tail,na.rm=TRUE),divergences=div,diagnostics_pass=good)
    b<-posterior::as_draws_df(f)$b_application;q<-quantile(b,c(.025,.5,.975))
    rows[[length(rows)+1]]<-data.frame(outcome=y,n=nrow(dd),median=q[2],low=q[1],high=q[3],prob_positive=mean(b>0),diagnostics_pass=good)
    p<-brms::pp_check(f,type="bars",ndraws=100);plot_save(paste0("bayes_ppc_",y),p)
    # Cluster-marginal contrast: include estimated township effects at each observed township.
    a<-dd;bdata<-dd;a$application<-0;bdata$application<-1
    p0<-brms::posterior_epred(f,newdata=a,draw_ids=seq_len(500));p1<-brms::posterior_epred(f,newdata=bdata,draw_ids=seq_len(500))
    contrasts<-apply(p1-p0,c(1,3),mean)
    save_table(data.frame(category=1:5,mean=colMeans(contrasts),low=apply(contrasts,2,quantile,.025),high=apply(contrasts,2,quantile,.975)),paste0("bayes_probabilities_",y))
  }
  if(length(rows))save_table(do.call(rbind,rows),"bayesian_associations")
  if(length(diagnostics))save_table(do.call(rbind,diagnostics),"bayesian_diagnostics")
  file.path(OUT,"tables/bayesian_diagnostics.csv")
}
