###############################################################################@
## From NCBI ----
f <- "~/Tmp/ref_GRCh38.p12_top_level.gff3.gz"
if(!file.exists(f)){
   download.file(
      "ftp://ftp.ncbi.nlm.nih.gov/genomes/Homo_sapiens/GFF/ref_GRCh38.p12_top_level.gff3.gz",
      destfile=f
   )
}
gff <- read.table(
   f,
   sep="\t", header=FALSE, quote="",
   stringsAsFactors=FALSE,
   comment.char="#", fill=F
)

## * Chromosomes ----
chr <- gff[which(gff$V3=="region"),]
chrAnno <- as.data.frame(do.call(rbind, lapply(
   strsplit(chr$V9, split=";"),
   function(x){
      toRet <- c(
         sub("^chromosome=", "", grep("^chromosome=", x, value=TRUE)),
         sub("^genome=", "", grep("^genome=", x, value=TRUE))
      )
      if(length(toRet)==0){
         toRet <- rep(NA, 2)
      }
      return(toRet)
   }
)), stringsAsFactors=FALSE)
colnames(chrAnno) <- c("chromosome", "genome")
chr <- data.frame(
   "chrid"=chr$V1, chrAnno,
   stringsAsFactors=FALSE
)
chr <- chr[which(!duplicated(chr$chrid)),]
rownames(chr) <- chr$chrid
rm(chrAnno)

## * Genes ----
genes <- gff[which(gff$V3 %in% c("gene", "pseudogene")),]
geneIds <-unlist(lapply(
   strsplit(genes$V9, split=";"),
   function(x){
      dbxref <- unlist(strsplit(
         sub("^Dbxref=", "", grep("^Dbxref=", x, value=TRUE)),
         split=","
      ))
      toRet <- sub(
         "^GeneID:", "",
         grep("^GeneID", dbxref, value=T)
      )
      if(length(toRet)==0){
         toRet <- NA
      }
      return(toRet)
   }
))
genes <- data.frame(
   "gene"=geneIds,
   chr[genes$V1,],
   "start"=genes$V4,
   "stop"=genes$V5,
   "direction"=genes$V7,
   stringsAsFactors=FALSE
)
genes <- genes[
   which(genes$genome %in% c("chromosome", "mitochondrion")),
   c("gene", "chromosome", "start", "stop", "direction")
]
genes[which(genes$chromosome=="mitochondrion"), "chromosome"] <- "MT"
genes <- genes[
   which(
      genes$chromosome!="Y" |
         !genes$gene %in% genes$gene[which(duplicated(genes$gene))]
   ),
]
rownames(genes) <- genes$gene
entrezGenes <- genes
rm(genes, chr, geneIds, gff)

###############################################################################@
## From Ensembl ----
f <- "~/Tmp/Homo_sapiens.GRCh38.92.gff3.gz"
if(!file.exists(f)){
   download.file(
      "ftp://ftp.ensembl.org/pub/release-92/gff3/homo_sapiens/Homo_sapiens.GRCh38.92.gff3.gz",
      destfile=f
   )
}
gff <- read.table(
   f,
   sep="\t", header=FALSE, quote="",
   stringsAsFactors=FALSE,
   comment.char="#", fill=F
)
genes <- gff[which(gff$V3 %in% c("gene", "ncRNA_gene", "pseudogene")),]
geneIds <- unlist(lapply(
   strsplit(genes$V9, split=";"),
   function(x){
      toRet <- sub(
         "^gene_id=", "",
         grep("^gene_id=", x, value=T)
      )
      if(length(toRet)==0){
         toRet <- NA
      }
      return(toRet)
   }
))
genes <- data.frame(
   "gene"=geneIds,
   "chromosome"=genes$V1,
   "start"=genes$V4,
   "stop"=genes$V5,
   "direction"=genes$V7,
   stringsAsFactors=FALSE
)
genes <- genes[which(genes$chromosome %in% c(1:22, "X", "Y", "MT")), ]
rownames(genes) <- genes$gene
ensemblGenes <- genes

###############################################################################@
## Save the data ----
save(
   entrezGenes, ensemblGenes,
   file="~/Tmp/gene-locations.rda"
)
