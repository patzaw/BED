# load("~/Tmp/ConvTables-3rdTools.rda")
load("~/Tmp/gene-locations.rda")

## Conversions ----
## * BED ----
library(BED)
beids <- getBeIds(
   be="Gene", source="Ens_gene", organism="human",
   restricted=FALSE
)
curBeid <- unique(beids$id[which(beids$db.deprecated=="FALSE")])
depBeid <- unique(beids$id[which(beids$db.deprecated!="FALSE")])
bedConv <- convBeIds(
   ids=beids$id, from="Gene", from.source="Ens_gene", from.org="human",
   to.source="EntrezGene", restricted=TRUE
)
## * biomaRt
library(biomaRt)
bmEnsembl = useMart("ensembl",dataset="hsapiens_gene_ensembl")
bmConv <- getBM(
   values = unique(beids$id),
   filters = 'ensembl_gene_id',
   attributes=c('ensembl_gene_id', 'entrezgene'),
   mart = bmEnsembl
)
# ## * mygene ----
# library(mygene)
# mgConv <- queryMany(
#    qterm=unique(beids$id),
#    scopes = "ensembl.gene",
#    fields="entrezgene",
#    species="human"
# )
# ## * gProfileR ----
# library(gProfileR)
# gpConv <- gconvert(
#    query=unique(beids$id),
#    target="ENTREZGENE_ACC",
#    organism="hsapiens",
#    filter_na=FALSE,
#    df=FALSE
# )
# gpConv <- do.call(
#    rbind,
#    lapply(
#       gpConv,
#       function(x){
#          data.frame(
#             alias=as.character(x[,"alias"]),
#             target=as.character(x[,"target"]),
#             stringsAsFactors=FALSE
#          )
#       }
#    )
# )
# gpConv$target <- sub("ENTREZGENE_ACC:", "", gpConv$target)
# gpConv$target <- ifelse(gpConv$target=="N/A", NA, gpConv$target)
# rownames(gpConv) <- c()
# gpConv <- unique(gpConv)


## Converted by biomaRt
mapping <- bmConv[which(
   !is.na(bmConv$entrezgene) & bmConv$ensembl_gene_id %in% curBeid
),]
colnames(mapping) <- c("ens", "entrez")
mapping$entrez <- as.character(mapping$entrez)
ensLoc <- ensemblGenes[mapping$ens,]
rownames(ensLoc) <- c()
ensLoc$gene <- mapping$ens
entrezLoc <- entrezGenes[mapping$entrez,]
rownames(entrezLoc) <- c()
entrezLoc$gene <- mapping$entrez
## * Not on canonical chromosome ----
message("Not on canonical chromosome")
print(sum(is.na(ensLoc$chromosome) | is.na(entrezLoc$chromosome)))
## * On canonical chromosome ----
message("On cannonical chromosome")
print(sum(!is.na(ensLoc$chromosome) & !is.na(entrezLoc$chromosome)))
toTake <- which(!is.na(ensLoc$chromosome) & !is.na(entrezLoc$chromosome))
censLoc <- ensLoc[toTake,]
centrezLoc <- entrezLoc[toTake,]
message("Different chromosomes")
print(sum(censLoc$chromosome != centrezLoc$chromosome))
toTake <- which(censLoc$chromosome == centrezLoc$chromosome)
ccensLoc <- censLoc[toTake,]
ccentrezLoc <- centrezLoc[toTake,]
sdiff <- ccensLoc$start-ccentrezLoc$start
ediff <- ccensLoc$stop-ccentrezLoc$stop
rdiff <- ediff-sdiff
boxplot(
   list("Start"=abs(sdiff), "Stop"=abs(ediff)),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)
boxplot(
   list("Length"=abs(rdiff)),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)
sdiff1 <- sdiff
ediff1 <- ediff
rdiff1 <- rdiff


## Converted by BED only
mapping <- bedConv[which(
   !is.na(bedConv$to) & bedConv$from %in% curBeid &
      ! bedConv$from %in% bmConv$ensembl_gene_id[which(!is.na(bmConv$entrezgene))]
), c("from", "to")]
colnames(mapping) <- c("ens", "entrez")
mapping$entrez <- as.character(mapping$entrez)
ensLoc <- ensemblGenes[mapping$ens,]
rownames(ensLoc) <- c()
ensLoc$gene <- mapping$ens
entrezLoc <- entrezGenes[mapping$entrez,]
rownames(entrezLoc) <- c()
entrezLoc$gene <- mapping$entrez
## * Not on canonical chromosome ----
message("Not on canonical chromosome")
print(sum(is.na(ensLoc$chromosome) | is.na(entrezLoc$chromosome)))
## * On canonical chromosome ----
message("On cannonical chromosome")
print(sum(!is.na(ensLoc$chromosome) & !is.na(entrezLoc$chromosome)))
toTake <- which(!is.na(ensLoc$chromosome) & !is.na(entrezLoc$chromosome))
censLoc <- ensLoc[toTake,]
centrezLoc <- entrezLoc[toTake,]
message("Different chromosomes")
print(sum(censLoc$chromosome != centrezLoc$chromosome))
toTake <- which(censLoc$chromosome == centrezLoc$chromosome)
ccensLoc <- censLoc[toTake,]
ccentrezLoc <- centrezLoc[toTake,]
sdiff <- ccensLoc$start-ccentrezLoc$start
ediff <- ccensLoc$stop-ccentrezLoc$stop
rdiff <- ediff-sdiff
boxplot(
   list("Start"=abs(sdiff), "Stop"=abs(ediff)),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)
boxplot(
   list("Length"=abs(rdiff)),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)

boxplot(
   list(
      "Start BM"=abs(sdiff1),
      "Start BED"=abs(sdiff),
      "Stop BM"=abs(ediff1),
      "Stop BED"=abs(ediff)
   ),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)
boxplot(
   list(
      "Length BM"=abs(rdiff1),
      "Legnth BED"=abs(rdiff)
   ),
   outline=FALSE,
   col="grey",
   ylab="|Ensembl - NCBI location|"
)
