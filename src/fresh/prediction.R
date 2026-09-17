group_folds<-function(g,k=5,seed=SEED){set.seed(seed);u<-sample(unique(g));map<-setNames(rep(seq_len(k),length.out=length(u)),u);unname(map[g])}
design_matrix<-function(d,features){model.matrix(reformulate(features),data=d,na.action=na.pass)[,-1,drop=FALSE]}
preprocess<-function(a,b){
  for(j in seq_len(ncol(a))){med<-median(a[,j],na.rm=TRUE);if(!is.finite(med))med<-0;a[is.na(a[,j]),j]<-med;b[is.na(b[,j]),j]<-med}
  mu<-colMeans(a);ss<-apply(a,2,sd);ss[!is.finite(ss)|ss==0]<-1
  list(train=sweep(sweep(a,2,mu,"-"),2,ss,"/"),test=sweep(sweep(b,2,mu,"-"),2,ss,"/"))
}
learn_predict<-function(method,par,a,y,b){
  pp<-preprocess(a,b);a<-pp$train;b<-pp$test
  if(method=="mean")return(rep(mean(y),nrow(b)))
  if(method=="elastic_net"){f<-glmnet::glmnet(a,y,alpha=par$alpha,lambda=par$lambda,standardize=FALSE);return(as.numeric(predict(f,b,s=par$lambda)))}
  if(method=="random_forest"){f<-ranger::ranger(x=as.data.frame(a),y=y,num.trees=400,min.node.size=par$node,mtry=min(ncol(a),par$mtry),seed=SEED,num.threads=1);return(predict(f,as.data.frame(b))$predictions)}
  if(method=="boosting"){f<-gbm::gbm.fit(x=a,y=y,distribution="gaussian",n.trees=par$trees,interaction.depth=par$depth,shrinkage=.03,n.minobsinnode=15,bag.fraction=.8,verbose=FALSE);return(as.numeric(predict(f,b,n.trees=par$trees)))}
  if(method=="GAM"){
    aa<-as.data.frame(a);bb<-as.data.frame(b);names(aa)<-names(bb)<-make.names(colnames(a));aa$y<-y
    terms<-names(bb);terms[terms%in%c("age","log_income","log_area")]<-paste0("s(",terms[terms%in%c("age","log_income","log_area")],",k=4)")
    f<-mgcv::gam(as.formula(paste("y ~",paste(terms,collapse=" + "))),data=aa,method="REML",select=TRUE);return(as.numeric(predict(f,bb)))}
}
run_prediction<-function(prepared){
  d<-readRDS(prepared)$data;d<-d[!is.na(d$tolerance3),];features<-c("application",BG,RES,"conflict_wb","conflict_all","log_damage","log_loss","ic1","word_mean","benefit","report_count","info_count","prevention_used","prevention_eff0")
  # model.frame with na.pass preserves rows; all categorical levels are questionnaire-defined.
  mf<-model.frame(reformulate(features),data=d,na.action=na.pass);X<-model.matrix(reformulate(features),mf)[,-1,drop=FALSE];y<-d$tolerance3
  folds<-group_folds(d$township);save_table(data.frame(ID=d$ID,township=d$township,outer_fold=folds),"prediction_folds")
  grids<-list(mean=list(list()),elastic_net=lapply(1:6,function(i){g<-expand.grid(alpha=c(0,.5,1),lambda=c(.01,.1));as.list(g[i,])}),GAM=list(list()),
    random_forest=lapply(1:4,function(i){g<-expand.grid(node=c(5,15),mtry=c(5,10));as.list(g[i,])}),boosting=lapply(1:4,function(i){g<-expand.grid(trees=c(100,300),depth=c(1,2));as.list(g[i,])}))
  preds<-list();selected<-list();importance<-list()
  for(k in 1:5){tr<-which(folds!=k);te<-which(folds==k);inner<-group_folds(d$township[tr],3,SEED+k)
    stopifnot(!length(intersect(d$township[tr],d$township[te])))
    for(method in names(grids)){
      grid<-grids[[method]];loss<-sapply(grid,function(par)mean(sapply(1:3,function(j){ia<-tr[inner!=j];ib<-tr[inner==j];p<-attempt("inner_predict",learn_predict(method,par,X[ia,,drop=FALSE],y[ia],X[ib,,drop=FALSE]));if(is.null(p))return(Inf);mean((y[ib]-p)^2)})))
      best<-which.min(loss);par<-grid[[best]];p<-attempt("outer_predict",learn_predict(method,par,X[tr,,drop=FALSE],y[tr],X[te,,drop=FALSE]));if(is.null(p))next
      preds[[length(preds)+1]]<-data.frame(ID=d$ID[te],fold=k,method=method,observed=y[te],predicted=p)
      selected[[length(selected)+1]]<-data.frame(fold=k,method=method,parameters=jsonlite::toJSON(par,auto_unbox=TRUE),inner_MSE=loss[best])
      if(method=="random_forest"){
        base<-mean((y[te]-p)^2)
        for(j in seq_len(ncol(X))){drops<-sapply(1:5,function(b){set.seed(SEED+k*1000+j*10+b);xx<-X[te,,drop=FALSE];xx[,j]<-sample(xx[,j]);pp<-learn_predict(method,par,X[tr,,drop=FALSE],y[tr],xx);mean((y[te]-pp)^2)-base});importance[[length(importance)+1]]<-data.frame(fold=k,feature=colnames(X)[j],delta_MSE=mean(drops))}
      }
    }
  }
  pr<-do.call(rbind,preds);save_table(pr,"prediction_oof");save_table(do.call(rbind,selected),"prediction_tuning")
  met<-do.call(rbind,lapply(split(pr,pr$method),function(v)data.frame(method=v$method[1],n=nrow(v),RMSE=sqrt(mean((v$observed-v$predicted)^2)),MAE=mean(abs(v$observed-v$predicted)),R2=1-sum((v$observed-v$predicted)^2)/sum((v$observed-mean(v$observed))^2))))
  save_table(met,"prediction_metrics");if(length(importance))save_table(do.call(rbind,importance),"heldout_importance")
  transfer<-list()
  for(cty in levels(d$county)){tr<-which(d$county!=cty);te<-which(d$county==cty)
    for(method in c("mean","elastic_net","random_forest")){par<-switch(method,mean=list(),elastic_net=list(alpha=.5,lambda=.1),random_forest=list(node=15,mtry=5));pp<-attempt("county_transfer",learn_predict(method,par,X[tr,,drop=FALSE],y[tr],X[te,,drop=FALSE]));if(!is.null(pp))transfer[[length(transfer)+1]]<-data.frame(test_county=cty,method=method,n=length(te),RMSE=sqrt(mean((y[te]-pp)^2)),R2=1-sum((y[te]-pp)^2)/sum((y[te]-mean(y[te]))^2))}}
  save_table(do.call(rbind,transfer),"county_transport")
  plot_save("prediction",ggplot2::ggplot(met,ggplot2::aes(RMSE,reorder(method,-RMSE)))+ggplot2::geom_col(fill="#327f91")+ggplot2::labs(x="Out-of-fold RMSE (raw 1–5 three-item score)",y=NULL,title="Nested township-grouped prediction")+ggplot2::theme_minimal(base_size=12))
  file.path(OUT,"tables/prediction_metrics.csv")
}
run_adjustment<-function(prepared){
  d<-readRDS(prepared)$data;d<-d[!is.na(d$tolerance3),];X<-model.matrix(reformulate(c(BG,RES)),d)[,-1,drop=FALSE];y<-d$tolerance3;D<-d$application
  all<-list();scores<-list()
  for(rep in 1:5){fold<-group_folds(d$township,5,SEED+rep);p<-mu0<-mu1<-rep(NA_real_,nrow(d))
    for(k in 1:5){tr<-which(fold!=k);te<-which(fold==k);pp<-preprocess(X[tr,,drop=FALSE],X[te,,drop=FALSE]);a<-pp$train;b<-pp$test
      # Hyperparameters fixed a priori for nuisance forests; cross-fitting is genuinely out of sample.
      fm<-ranger::ranger(x=as.data.frame(a),y=factor(D[tr],levels=0:1),probability=TRUE,num.trees=500,min.node.size=15,seed=SEED,num.threads=1)
      p[te]<-predict(fm,as.data.frame(b))$predictions[,"1"]
      for(g in 0:1){idx<-which(D[tr]==g);f<-ranger::ranger(x=as.data.frame(a[idx,,drop=FALSE]),y=y[tr[idx]],num.trees=500,min.node.size=10,seed=SEED,num.threads=1);pred<-predict(f,as.data.frame(b))$predictions;if(g==0)mu0[te]<-pred else mu1[te]<-pred}
    }
    clipped<-pmin(pmax(p,.01),.99);phi<-mu1-mu0+D*(y-mu1)/clipped-(1-D)*(y-mu0)/(1-clipped);est<-mean(phi);G<-length(unique(d$township));cs<-tapply(phi-est,d$township,sum);se<-sqrt(G/(G-1)*sum(cs^2))/nrow(d)
    w<-D/clipped+(1-D)/(1-clipped)
    all[[rep]]<-data.frame(repetition=rep,estimate_raw=est,se=se,low=est-qt(.975,G-1)*se,high=est+qt(.975,G-1)*se,min_propensity=min(p),max_propensity=max(p),clipped=sum(p<.01|p>.99),effective_sample_size=sum(w)^2/sum(w^2),estimand="Cross-fitted adjusted contrast; causal interpretation requires unverified assumptions")
    scores[[rep]]<-data.frame(ID=d$ID,repetition=rep,fold=fold,application=D,propensity=p,mu0=mu0,mu1=mu1,score=phi,weight=w)
  }
  save_table(do.call(rbind,all),"aipw_summary");ss<-do.call(rbind,scores);save_table(ss,"aipw_oof")
  first<-ss[ss$repetition==1,];balance<-lapply(seq_len(ncol(X)),function(j){v<-X[,j];den<-sqrt((var(v[D==0])+var(v[D==1]))/2);data.frame(variable=colnames(X)[j],unweighted=(mean(v[D==1])-mean(v[D==0]))/den,weighted=(weighted.mean(v[D==1],first$weight[D==1])-weighted.mean(v[D==0],first$weight[D==0]))/den)})
  save_table(do.call(rbind,balance),"aipw_balance")
  plot_save("overlap",ggplot2::ggplot(first,ggplot2::aes(propensity,fill=factor(application)))+ggplot2::geom_histogram(position="identity",alpha=.5,bins=25)+ggplot2::labs(x="Out-of-fold propensity",fill="Applied",title="Overlap must be assessed before interpreting adjustment")+ggplot2::theme_minimal(base_size=12))
  # Omitted-variable bias contours for linear benchmark; point-estimate sensitivity, not cluster-adjusted causal bounds.
  f<-lm(reformulate(c("application",BG,RES),"tolerance3"),d);fd<-lm(reformulate(c(BG,RES),"application"),d)
  grid<-expand.grid(partial_R2_y=c(0,.01,.03,.05,.1,.2),partial_R2_d=c(0,.01,.03,.05,.1,.2));grid$bias<-sd(residuals(f))/sd(residuals(fd))*sqrt(grid$partial_R2_y*grid$partial_R2_d/(1-grid$partial_R2_d));grid$estimate<-coef(f)["application"];grid$toward_zero<-grid$estimate-sign(grid$estimate)*grid$bias
  save_table(grid,"unmeasured_confounding_grid");file.path(OUT,"tables/aipw_summary.csv")
}
