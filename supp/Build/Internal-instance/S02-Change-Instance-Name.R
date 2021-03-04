library(here)
wd <- here("../working")
library(BED)
connectToBed(
   url="localhost:5420",
   remember=FALSE,
   useCache=TRUE,
   importPath=file.path(wd, "neo4jImport")
)
bedInstance <- paste0(attr(checkBedConn(), "dbVersion")$instance, "-Internal")
bedVersion <- attr(checkBedConn(), "dbVersion")$version
BED:::setBedVersion(bedInstance=bedInstance, bedVersion=bedVersion)
