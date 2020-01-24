## First "Build & Reload" or "Install and Restart" in rstudio
## Then >devtools::build_vignettes() in rstudio
## Move doc directory into inst/ directory
## Then "Build & Reload" or "Install and Restart" in rstudio

date;
## In parent folder
R CMD build --resave-data --no-build-vignettes BED;
# R CMD check BED_0.8.1.tar.gz
date;


