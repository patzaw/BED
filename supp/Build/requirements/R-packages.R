install.packages("BiocManager")
BiocManager::install(ask = FALSE)
BiocManager::install(
   c(
   "BED",
   "knitr",
   "rmarkdown",
   "biomaRt",
   "GEOquery",
   "base64enc",
   "htmltools",
   "RCurl",
   "magrittr",
   "devtools",
   "rvest"
   ),
   ask = FALSE
)
devtools::install_github("patzaw/BED")
