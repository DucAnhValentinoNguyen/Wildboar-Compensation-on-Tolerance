#!/usr/bin/env Rscript
# Invoke from project root. No legacy scripts are sourced.
.libPaths(c(normalizePath(".r-library",mustWork=FALSE),.libPaths()))
args<-commandArgs(trailingOnly=TRUE)
if("--restore"%in%args){
  if(!requireNamespace("renv",quietly=TRUE))install.packages("renv",repos="https://cloud.r-project.org",lib=".r-library")
  if(file.exists("renv.lock")) renv::restore(lockfile="renv.lock",library=".r-library",prompt=FALSE)
  else message("No renv.lock is committed; using the project-local .r-library installed for this release.")
}else if("--render"%in%args){
  source("src/fresh/common.R");source("src/fresh/reporting.R");render_deliverables()
}else if("--verify"%in%args){
  source("src/fresh/common.R");source("src/fresh/validate.R");validate_project()
}else{
  targets::tar_make(callr_function=NULL)
}
