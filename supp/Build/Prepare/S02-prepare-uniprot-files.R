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

## It's faster to first download files with uGet or similar download manager
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_sprot_human.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_trembl_human.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_sprot_rodents.xml.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_trembl_rodents.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_sprot_mammals.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_trembl_mammals.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_sprot_vertebrates.dat.gz
## - https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions/uniprot_trembl_vertebrates.dat.gz

ftp <- "https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/taxonomic_divisions"
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
      ftp='https://ftp.expasy.org/databases/uniprot',
      env=parent.frame(n=1)
   )
}
