library(here)

dumpDir <- here("../working/taxdump/")

## Because of firewall issues the following file could be downloaded manually
utils::download.file(
   "ftp://ftp.ncbi.nlm.nih.gov/pub/taxonomy/taxdump.tar.gz",
   file.path(dumpDir, "taxdump.tar.gz"),
   quiet=TRUE
)
dumpDate <- Sys.Date()
save(dumpDate, file=file.path(dumpDir, "dumpDate.rda"))

system(
   sprintf('cd %s ; tar xzf taxdump.tar.gz ; cd -', dumpDir),
   ignore.stdout=TRUE
)
