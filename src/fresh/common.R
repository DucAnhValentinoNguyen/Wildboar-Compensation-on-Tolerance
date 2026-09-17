ROOT <- normalizePath(Sys.getenv("WILDBOAR_ROOT", "."), mustWork=TRUE)
.libPaths(c(file.path(ROOT, ".r-library"), .libPaths()))
if(!requireNamespace("digest",quietly=TRUE)) stop("digest is required; run Rscript run_project.R --restore")
OUT <- file.path(ROOT, "results", "fresh")
dir.create(OUT, recursive=TRUE, showWarnings=FALSE)
for (s in c("tables", "figures", "models", "logs", "report", "presentation")) dir.create(file.path(OUT,s), showWarnings=FALSE)
SEED <- 20260917L
set.seed(SEED)
options(stringsAsFactors=FALSE, warn=1)
save_table <- function(x,n) {write.csv(x,file.path(OUT,"tables",paste0(n,".csv")),row.names=FALSE,na=""); invisible(x)}
save_model <- function(x,n) saveRDS(x,file.path(OUT,"models",paste0(n,".rds")))
log_event <- function(stage,status,message) {
  cat(paste(format(Sys.time(),tz="UTC"),stage,status,gsub("[\r\n]+"," ",message),sep="\t"),"\n",file=file.path(OUT,"logs","events.tsv"),append=TRUE)
}
attempt <- function(label,expr) tryCatch(withCallingHandlers(expr,warning=function(w) {log_event(label,"warning",conditionMessage(w));invokeRestart("muffleWarning")}),error=function(e){log_event(label,"failed",conditionMessage(e));NULL})
z <- function(x) as.numeric(scale(x))
mean_available <- function(x) {v<-rowMeans(x,na.rm=TRUE);v[!is.finite(v)]<-NA_real_;v}
numeric_safely <- function(x) suppressWarnings(as.numeric(x))
plot_save <- function(n,p,w=9,h=5) ggplot2::ggsave(file.path(OUT,"figures",paste0(n,".png")),p,width=w,height=h,dpi=160,bg="white")
fmt <- function(x,k=3) ifelse(is.finite(x),formatC(x,digits=k,format="f"),"NA")
BG <- c("county","np","age","gender","education","household_size")
RES <- c("log_income","agri_share","log_area","log_livestock","log_assets")
EXPL <- c("conflict_wb","conflict_all","log_damage","log_loss","ic","benefit","report_count","info_count","prevention_used","prevention_eff0")
TOLS <- c("tol1","tol2","tol3","tol4")
cluster_coef <- function(fit,d,term="application",group="township") {
  v<-sandwich::vcovCL(fit,cluster=d[[group]],type="HC1",cadjust=TRUE)
  b<-coef(fit)[term];s<-sqrt(diag(v))[term];df<-length(unique(d[[group]]))-1
  data.frame(term=term,estimate=unname(b),se=unname(s),low=unname(b-qt(.975,df)*s),high=unname(b+qt(.975,df)*s),p=2*pt(-abs(b/s),df),n=nrow(d),clusters=df+1)
}
bootstrap_indices <- function(d,b) {
  set.seed(SEED+b)
  unlist(lapply(split(seq_len(nrow(d)),d$county),function(ii){g<-unique(d$township[ii]);draw<-sample(g,length(g),TRUE);unlist(lapply(draw,function(a)ii[d$township[ii]==a]),use.names=FALSE)}),use.names=FALSE)
}
