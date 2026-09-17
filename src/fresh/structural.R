pls_model_syntax<-function(kind="mediation") {
  measurement<-"Tol =~ tol1 + tol2 + tol4\nIC <~ ic1 + word_mean\nPS <~ report_count + info_count\nTC <~ log_damage + log_loss\nIB <~ benefit\nCE <~ application"
  if(kind=="four_items")measurement<-sub("Tol =~ tol1 + tol2 + tol4","Tol =~ tol1 + tol2 + tol3 + tol4",measurement,fixed=TRUE)
  if(kind=="ic1_only")measurement<-sub("IC <~ ic1 + word_mean","IC <~ ic1",measurement,fixed=TRUE)
  structure<-"Tol ~ CE + IC + PS + TC + IB"
  if(kind!="baseline")structure<-paste(structure,"IC ~ CE\nPS ~ CE",sep="\n")
  if(kind=="extended"){
    measurement<-paste(measurement,"Conflict <~ conflict_wb + conflict_all\nUse <~ prevention_used\nEff <~ prevention_eff0",sep="\n")
    structure<-"Tol ~ CE + IC + PS + TC + IB + Conflict + Use + Eff\nIC ~ CE + Conflict + Use + Eff\nPS ~ CE + Conflict\nTC ~ Conflict\nIB ~ Conflict"
  }
  paste(measurement,structure,sep="\n")
}
pls_fit<-function(dd,syntax) cSEM::csem(.data=dd,.model=syntax,.disattenuate=FALSE,.iter_max=300)
oriented<-function(f,dd){
  scores<-f$Estimates$Construct_scores;P<-f$Estimates$Path_estimates
  anchors<-c(Tol="tol1",IC="ic1",PS="report_count",TC="log_loss",IB="benefit",CE="application",Conflict="conflict_wb",Use="prevention_used",Eff="prevention_eff0")
  signs<-sapply(colnames(scores),function(n){v<-cor(scores[,n],dd[[anchors[[n]]]]);ifelse(is.finite(v)&&v<0,-1,1)})
  scores<-sweep(scores,2,signs,"*");P<-P*outer(signs[rownames(P)],signs[colnames(P)])
  list(scores=as.data.frame(scores),paths=P)
}
pls_statistics<-function(f,dd){
  o<-oriented(f,dd);P<-o$paths;s<-o$scores
  # Two-stage observed product of newly estimated scores in every bootstrap.
  s$application<-dd$application;s$ic_center<-s$IC-mean(s$IC)
  base<-lm(Tol~application+IC+PS+TC+IB,data=s)
  mod<-lm(Tol~application+IC+PS+TC+IB+application:ic_center,data=s)
  r0<-summary(base)$r.squared;r1<-summary(mod)$r.squared
  c(direct=P["Tol","CE"],indirect_IC=P["IC","CE"]*P["Tol","IC"],indirect_PS=P["PS","CE"]*P["Tol","PS"],
    total=P["Tol","CE"]+P["IC","CE"]*P["Tol","IC"]+P["PS","CE"]*P["Tol","PS"],
    IC_to_Tol=P["Tol","IC"],PS_to_Tol=P["Tol","PS"],IB_to_Tol=P["Tol","IB"],TC_to_Tol=P["Tol","TC"],
    interaction=unname(coef(mod)["application:ic_center"]),interaction_f2=(r1-r0)/(1-r1))
}
run_structural<-function(prepared){
  d<-readRDS(prepared)$data
  fields<-c("tol1","tol2","tol3","tol4","ic1","word_mean","report_count","info_count","log_damage","log_loss","benefit","application","conflict_wb","conflict_all","prevention_used","prevention_eff0","township","county")
  dd<-d[complete.cases(d[fields]),fields];fits<-list();paths<-list();quality<-list()
  for(kind in c("baseline","mediation","extended","four_items","ic1_only")){
    f<-attempt(paste("PLS",kind),pls_fit(dd,pls_model_syntax(kind)));if(is.null(f))next;fits[[kind]]<-f
    P<-oriented(f,dd)$paths;ix<-which(f$Information$Model$structural!=0,arr.ind=TRUE)
    paths[[kind]]<-data.frame(model=kind,to=rownames(P)[ix[,1]],from=colnames(P)[ix[,2]],estimate=P[ix])
    a<-attempt("PLS_assessment",cSEM::assess(f,.quality_criterion=c("r2","f2","ave","reliability","vifmodeB","srmr")))
    save_model(a,paste0("pls_assessment_",kind));capture.output(print(a),file=file.path(OUT,"logs",paste0("pls_assessment_",kind,".txt")))
    quality[[kind]]<-data.frame(model=kind,n=nrow(dd),admissible=!any(cSEM::verify(f)),R2_Tol=f$Estimates$R2["Tol"],SRMR=if(!is.null(a))a$SRMR else NA)
    save_table(data.frame(construct=rownames(f$Estimates$Weight_estimates),f$Estimates$Weight_estimates),paste0("pls_weights_",kind))
    save_table(data.frame(construct=rownames(f$Estimates$Loading_estimates),f$Estimates$Loading_estimates),paste0("pls_loadings_",kind))
  }
  save_table(do.call(rbind,paths),"pls_paths");save_table(do.call(rbind,quality),"pls_quality");save_model(fits,"pls_fits")
  f<-fits$mediation;if(is.null(f))stop("Primary PLS fit failed")
  point<-pls_statistics(f,dd);B<-5000L
  bp<-file.path(OUT,"models/pls_cluster_bootstrap.rds")
  if(file.exists(bp))boots<-readRDS(bp)else{
    boots<-parallel::mclapply(seq_len(B),function(b){idx<-bootstrap_indices(dd,b);db<-dd[idx,];
      tryCatch({ff<-suppressWarnings(pls_fit(db,pls_model_syntax()));if(any(cSEM::verify(ff)))stop("Inadmissible PLS fit");list(values=pls_statistics(ff,db),failure="")},error=function(e)list(values=setNames(rep(NA,length(point)),names(point)),failure=conditionMessage(e)))},mc.cores=8,mc.set.seed=FALSE)
    saveRDS(boots,bp)
  }
  bm<-do.call(rbind,lapply(boots,`[[`,"values"));save_table(data.frame(replicate=seq_len(B),bm,failure=vapply(boots,`[[`,character(1),"failure")),"pls_bootstrap_replicates")
  ci<-do.call(rbind,lapply(c(2000,5000),function(n)do.call(rbind,lapply(names(point),function(p){v<-bm[seq_len(n),p];good<-is.finite(v);q<-quantile(v[good],c(.025,.975));data.frame(parameter=p,estimate=point[p],low=q[1],high=q[2],p_centered=(1+sum(abs(v[good]-point[p])>=abs(point[p])))/(sum(good)+1),requested=n,successful=sum(good),failure_rate=mean(!good))}))))
  ci$p_centered[ci$parameter=="interaction_f2"]<-NA_real_
  save_table(ci,"pls_bootstrap_summary")
  plot_save("pls_paths",ggplot2::ggplot(subset(ci,requested==5000&parameter!="interaction_f2"),ggplot2::aes(estimate,reorder(parameter,estimate),xmin=low,xmax=high))+ggplot2::geom_pointrange()+ggplot2::geom_vline(xintercept=0,lty=2)+ggplot2::labs(x="PLS path / two-stage interaction (different scales; see report)",y=NULL,title="Cluster-bootstrap uncertainty includes measurement estimation")+ggplot2::theme_minimal(base_size=11))
  # Assessment of compositional invariance is a conventional individual-permutation diagnostic.
  gm<-"Tol =~ tol1 + tol2 + tol4\nIC <~ ic1 + word_mean\nPS <~ report_count + info_count\nTC <~ log_damage + log_loss\nIB <~ benefit\nTol ~ IC + PS + TC + IB"
  gs<-split(dd,dd$application);multi<-attempt("MGA_base",cSEM::csem(.data=gs,.model=gm,.disattenuate=FALSE,.iter_max=300))
  if(!is.null(multi)){
    mic<-attempt("MICOM",cSEM::testMICOM(multi,.R=999,.seed=SEED,.verbose=FALSE,.handle_inadmissibles="drop"));save_model(mic,"micom");capture.output(print(mic),file=file.path(OUT,"logs/micom.txt"))
    # Cluster bootstrap path differences; grouping exposure is deliberately excluded.
    extract<-function(db){g<-split(db,db$application);if(length(g)!=2)stop("Absent group");p<-lapply(g,function(a)oriented(pls_fit(a,gm),a)$paths["Tol",c("IC","PS","TC","IB")]);p[[2]]-p[[1]]}
    delta<-extract(dd)
    bootg<-parallel::mclapply(1:2000,function(b)tryCatch(suppressWarnings(extract(dd[bootstrap_indices(dd,b+10000),])),error=function(e)setNames(rep(NA,4),names(delta))),mc.cores=8,mc.set.seed=FALSE)
    mat<-do.call(rbind,bootg);save_model(mat,"mga_cluster_bootstrap")
    save_table(data.frame(path=names(delta),difference=delta,low=apply(mat,2,quantile,.025,na.rm=TRUE),high=apply(mat,2,quantile,.975,na.rm=TRUE),successful=colSums(is.finite(mat)),interpretation="Group-standardized path differences; conditional on adequate invariance; no equivalence claim"),"mga_cluster_differences")
  }
  file.path(OUT,"tables/pls_bootstrap_summary.csv")
}
