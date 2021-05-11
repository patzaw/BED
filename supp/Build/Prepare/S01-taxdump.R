library(here)

dumpDir <- here("../working/taxdump/")

## Because of firewall issues the following file could be downloaded manually
utils::download.file(
   "https://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdmp.zip",
   file.path(dumpDir, "taxdmp.zip"),
   quiet=TRUE
)
dumpDate <- Sys.Date()
save(dumpDate, file=file.path(dumpDir, "dumpDate.rda"))

system(
   sprintf('cd %s ; unzip taxdmp.zip ; cd -', dumpDir),
   ignore.stdout=TRUE
)
