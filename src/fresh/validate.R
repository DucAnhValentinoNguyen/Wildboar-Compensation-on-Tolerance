validate_project<-function(){
  checks<-list.files(file.path(OUT,"tables"),pattern="\\.csv$",full.names=TRUE)
  stopifnot(file.exists(file.path(ROOT,"docs/PLAN.md")),file.exists(file.path(ROOT,"docs/ANALYSIS_DECISIONS.md")),length(checks)>=50)
  d<-readRDS(file.path(OUT,"models/prepared.rds"))$data
  stopifnot(nrow(d)==625,sum(d$application)==277,all(is.na(d$timeliness[d$application==0])),all(!is.na(d$tol2)|!is.na(d$tol1)))
  source_map<-read.csv(file.path(ROOT,"results/repository_audit/tolerance_coding.csv"));stopifnot(all(source_map$mismatches==0))
  b<-read.csv(file.path(OUT,"tables/pls_bootstrap_summary.csv"));stopifnot(all(b$successful>0),all(b$failure_rate<.01))
  bay<-read.csv(file.path(OUT,"tables/bayesian_diagnostics.csv"));stopifnot(all(bay$diagnostics_pass))
  pred<-read.csv(file.path(OUT,"tables/prediction_metrics.csv"));stopifnot(all(is.finite(pred$RMSE)),all(pred$method%in%c("mean","elastic_net","GAM","random_forest","boosting")))
  files<-c(list.files(file.path(ROOT,"src/fresh"),full.names=TRUE),file.path(ROOT,c("_targets.R","run_project.R","docs/PLAN.md","docs/ANALYSIS_DECISIONS.md","docs/Analysis_Report.Rmd")))
  manifest<-list(checked_utc=format(Sys.time(),tz="UTC",usetz=TRUE),n_respondents=nrow(d),n_tables=length(checks),file_hashes=setNames(lapply(files,function(p)digest::digest(file=p,algo="sha256")),sub(paste0(ROOT,"/"),"",files,fixed=TRUE)))
  jsonlite::write_json(manifest,file.path(OUT,"validation.json"),pretty=TRUE,auto_unbox=TRUE)
  writeLines(c("VALIDATION PASSED",capture.output(str(manifest))),file.path(OUT,"logs/validation.txt"));TRUE
}
