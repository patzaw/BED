library(here)

##############################@
## Build documentation ----
devtools::document(pkg=here::here(), roclets = c('rd', 'collate', 'namespace'))
# install.packages(here::here(), repos=NULL)

##############################@
## Build and copy vignettes ----
rmarkdown::render(here("README.Rmd"))
devtools::build_vignettes()
dir.create(here("inst/doc"), showWarnings=FALSE)
for(f in list.files(here("doc"))){
   file.copy(
      file.path(here("doc"), f), file.path(here("vignettes"), f),
      overwrite=TRUE
   )
   file.copy(
      file.path(here("doc"), f), file.path(here("inst/doc"), f),
      overwrite=TRUE
   )
   if(sub("^.*[.]", "", f)=="html"){
      file.copy(
         file.path(here("doc"), f), file.path(here("pkgdown/assets"), f),
         overwrite=TRUE
      )
   }
   file.remove(file.path(here("doc"), f))
}
file.remove("doc")

##############################@
## Build website ----
unlink("docs", recursive=TRUE, force=TRUE)
pkgdown::build_site()

##############################@
## Build and check package ----
pv <- desc::desc_get_version(here())
system(paste(
   sprintf("cd %s", here("..")),
   "R CMD build BED",
   sprintf("cd ~/tmp"),
   sprintf(
      "R CMD check --as-cran --no-build-vignettes %s/BED_%s.tar.gz",
      here(".."),
      pv
   ),
   sep=" ; "
))
