library(BED)
library(here)
workingDirectory <- here("../working")

tois <- c(
   "9606",
   "10090",
   "10116",
   "9823",
   "7955"
)

ftp <- "ftp://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions"
avRel <- readLines(file.path(ftp, "reldate.txt"), n=1)
avRel <- sub(
   "^UniProt Knowledgebase Release ", "",
   sub(" consists of:$", "", avRel)
)

for(toi in tois){
   message(toi)
   BED:::dumpUniprotDb(
      taxOfInt=toi,
      release=avRel,
      ddir=workingDirectory,
      env=parent.frame(n=1)
   )
}
