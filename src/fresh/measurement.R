run_measurement<-function(prepared) {
  d<-readRDS(prepared)$data;it<-c(TOLS,"ic1","word1","word2","word3")
  dev<-d[d$partition=="development",it];val<-d[d$partition=="validation",it]
  pc<-attempt("polychoric",psych::polychoric(dev,correct=0,global=FALSE));save_model(pc,"polychoric_development")
  fits<-list();rows<-list();parallel_n<-NA
  if(!is.null(pc)) {
    save_table(data.frame(item=it,pc$rho),"polychoric_development")
    png(file.path(OUT,"figures/parallel_analysis.png"),width=1000,height=650,res=130)
    pa<-attempt("parallel_analysis",psych::fa.parallel(dev,fa="fa",fm="minres",cor="poly",correct=0,n.iter=100,plot=TRUE,show.legend=TRUE));dev.off()
    if(!is.null(pa))parallel_n<-pa$nfact
    for(k in 1:3){e<-attempt(paste0("EFA",k),psych::fa(pc$rho,nfactors=k,n.obs=sum(complete.cases(dev)),fm="minres",rotate="oblimin"));fits[[paste0("efa",k)]]<-e
      if(!is.null(e)){ll<-unclass(e$loadings);save_table(data.frame(item=rownames(ll),ll,communality=e$communality),paste0("efa_loadings_",k));rows[[length(rows)+1]]<-data.frame(factors=k,RMSR=e$rms,TLI=e$TLI,RMSEA=e$RMSEA[1],admissible=all(e$communality<=1 & e$communality>=0),development_n=nrow(dev),complete_n=sum(complete.cases(dev)),parallel_suggested=parallel_n)}}
  }
  if(length(rows))save_table(do.call(rbind,rows),"efa_comparison")
  pca<-prcomp(na.omit(d[it]),center=TRUE,scale.=TRUE);save_model(pca,"pca");save_table(data.frame(component=seq_along(pca$sdev),variance=pca$sdev^2/sum(pca$sdev^2),cumulative=cumsum(pca$sdev^2/sum(pca$sdev^2))),"pca_variance");save_table(data.frame(item=rownames(pca$rotation),pca$rotation),"pca_loadings")
  models<-list(two_factor_four="Tolerance =~ tol1 + tol2 + tol3 + tol4\nIntangible =~ ic1 + word1 + word2 + word3",
               two_factor_three="Tolerance =~ tol1 + tol2 + tol4\nIntangible =~ ic1 + word1 + word2 + word3",
               one_factor="Common =~ tol1 + tol2 + tol3 + tol4 + ic1 + word1 + word2 + word3")
  # Freeze a development-derived loading pattern before validation; no modification-index edits.
  if(is.finite(parallel_n)&&parallel_n%in%1:3&&!is.null(fits[[paste0("efa",parallel_n)]])){
    L<-unclass(fits[[paste0("efa",parallel_n)]]$loadings);membership<-max.col(abs(L));strong<-apply(abs(L),1,max)>=.4
    groups<-split(rownames(L)[strong],membership[strong]);groups<-groups[lengths(groups)>=3]
    if(length(groups))models$efa_frozen<-paste(vapply(seq_along(groups),function(i)paste0("F",i," =~ ",paste(groups[[i]],collapse=" + ")),character(1)),collapse="\n")
    else log_event("EFA_to_CFA","not_identified","No factor has >=3 primary loadings >=.4; no EFA-derived CFA fitted")
  }
  if(is.finite(parallel_n)&&parallel_n>3)log_event("EFA_to_CFA","unsupported","Parallel analysis suggests >3 factors among only eight items; no identified >=3-indicator-per-factor CFA inferred")
  save_table(data.frame(model=names(models),syntax=unlist(models)),"cfa_prespecified_syntax")
  cfrows<-list();loadings<-list()
  for(part in c("validation","full"))for(n in names(models)){
    dd<-if(part=="validation")d[d$partition=="validation",] else d
    fit<-attempt(paste("CFA",part,n),lavaan::cfa(models[[n]],data=dd,ordered=intersect(it,lavaan::lavNames(lavaan::lavaanify(models[[n]]),type="ov")),estimator="WLSMV",std.lv=TRUE,missing="pairwise"))
    if(!is.null(fit)){
      fits[[paste(part,n,sep="_")]]<-fit;ok<-isTRUE(lavaan::lavInspect(fit,"converged"));admissible<-attempt("CFA_postcheck",lavaan::lavInspect(fit,"post.check"))
      fm<-attempt("CFA_fitmeasures",lavaan::fitMeasures(fit,c("chisq.scaled","df.scaled","cfi.scaled","tli.scaled","rmsea.scaled","srmr")))
      if(!is.null(fm))cfrows[[length(cfrows)+1]]<-data.frame(partition=part,model=n,n=lavaan::lavInspect(fit,"nobs"),converged=ok,admissible=isTRUE(admissible),as.list(fm),check.names=FALSE)
      pe<-attempt("CFA_parameters",lavaan::parameterEstimates(fit,standardized=TRUE));if(!is.null(pe)){pe$model<-n;pe$partition<-part;loadings[[length(loadings)+1]]<-pe}
    }
  }
  if(length(cfrows))save_table(do.call(rbind,cfrows),"cfa_fit");if(length(loadings))save_table(do.call(rbind,loadings),"cfa_parameters")
  # HTMT is a descriptive diagnostic for the proposed reflective cost/tolerance blocks only.
  htmt<-function(a,b){C<-abs(cor(d[c(a,b)],use="pairwise.complete.obs"));na<-length(a);nb<-length(b);A<-C[seq_len(na),seq_len(na)];B<-C[na+seq_len(nb),na+seq_len(nb)];mean(C[seq_len(na),na+seq_len(nb)])/sqrt(mean(A[lower.tri(A)])*mean(B[lower.tri(B)]))}
  save_table(data.frame(comparison=c("Tolerance4 vs IC reflective hypothesis","Tolerance3 vs IC reflective hypothesis","Institutions vs IC (NOT applicable to formative blocks)"),htmt=c(htmt(TOLS,c("ic1","word1","word2","word3")),htmt(c("tol1","tol2","tol4"),c("ic1","word1","word2","word3")),NA)),"htmt_scope")
  save_model(fits,"measurement_fits");log_event("measurement","success","EFA/PCA and frozen theory/validation CFA attempted; consult diagnostics");file.path(OUT,"models/measurement_fits.rds")
}
