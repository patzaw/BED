library(limma)

###############################################################################@
## File locations
ddir <- "~/Tmp/BED-Comp-UseCase/"
dir.create(ddir, showWarnings=FALSE)

###############################################################################@
## Preprocessing Hs Skin data ----

## * Downloading the data
eddir <- file.path(ddir, "E-GEOD-13355")
dir.create(eddir, showWarnings=FALSE)
af <- file.path(eddir, "E-GEOD-13355.sdrf.txt")
if(!file.exists(af)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-13355/E-GEOD-13355.sdrf.txt",
      destfile=af
   )
}
dfz <- file.path(eddir, "E-GEOD-13355.processed.1.zip")
if(!file.exists(dfz)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-13355/E-GEOD-13355.processed.1.zip",
      destfile=dfz
   )
}
unzip(dfz, exdir=eddir)
df <- file.path(eddir, "E-GEOD-13355-processed-data-1721515941.txt")

## * Load data ----
hsSkin.raw <- read.table(
   df,
   sep="\t", header=F, row.names=1, skip=2,
   stringsAsFactors = F, comment.char = "", quote="", check.names=FALSE
)
cn <- read.table(
   df,
   sep="\t", header=T, row.names=1, nrows=2,
   stringsAsFactors = F, comment.char = "", quote=""
)
colnames(hsSkin.raw) <- colnames(cn)
rm(cn)
hsSkin.d <- normalizeQuantiles(hsSkin.raw)
attr(hsSkin.raw, "scope") <- attr(hsSkin.d, "scope") <- list(
   be="Probe",
   source="GPL570",
   organism="Homo sapiens"
)
hsSkin.p <- read.table(
   af,
   sep="\t", header=T, stringsAsFactors=FALSE,
   comment.char="", quote="", check.names=FALSE
)
hsSkin.p <- hsSkin.p[,c(
   "Scan Name",
   "Characteristics[individual]",
   "Characteristics[disease]",
   "Characteristics[clinical information]"
)]
colnames(hsSkin.p) <- c(
   "Sample", "Individual", "Disease", "Type"
)
rownames(hsSkin.p) <- hsSkin.p$Sample
hsSkin.p <- hsSkin.p[colnames(hsSkin.d),]
hsSkin.p$Type <- sub(" *$", "", hsSkin.p$Type)
hsSkin.p$Type <- ifelse(
   hsSkin.p$Type=="lesional", "L",
   ifelse(
      hsSkin.p$Type=="non lesional", "NL",
      "HC"
   )
)

## * DE ----
d <- hsSkin.d[,which(hsSkin.p$Disease=="psoriasis")]
p <- hsSkin.p[which(hsSkin.p$Disease=="psoriasis"),]
individual <- as.factor(p$Individual)
type <- as.factor(p$Type)
design <- model.matrix(~ type + individual + 0)
colnames(design) <- sub(
   "^type", "",
   sub(
      "^individual", "ind.",
      colnames(design)
   )
)
contrast.matrix <- makeContrasts(
   L - NL,
   levels=design
)
fit <- lmFit(
   d,
   design=design
)
fit <- contrasts.fit(fit, contrast.matrix)
fit <- eBayes(fit)
deg <- topTable(fit, number=Inf)
hsSkin.DE <- deg
rm(
   af, df, dfz, eddir,
   d, p, individual, type, design, contrast.matrix, fit, deg
)

###############################################################################@
## Preprocessing Hs Keratinocytes data ----

## * Downloading the data
eddir <- file.path(ddir, "E-GEOD-24767")
dir.create(eddir, showWarnings=FALSE)
af <- file.path(eddir, "E-GEOD-24767.sdrf.txt")
if(!file.exists(af)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-24767/E-GEOD-24767.sdrf.txt",
      destfile=af
   )
}
dfz <- file.path(eddir, "E-GEOD-24767.processed.1.zip")
if(!file.exists(dfz)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-24767/E-GEOD-24767.processed.1.zip",
      destfile=dfz
   )
}
unzip(dfz, exdir=eddir)

## * Load data ----
fl <- list.files(
   eddir,
   pattern="_sample_table[.]txt$",
   full.names=TRUE
)
rm(hsKera.raw, hsKera.pval)
for(f in fl){
   cn <- sub("_sample_table[.]txt$", "", basename(f))
   toAdd <- read.table(
      f,
      sep="\t", header=F, row.names=1, skip=2,
      stringsAsFactors = F, comment.char = "", quote="", check.names=FALSE
   )
   toAddVal <- toAdd[,"V2", drop=FALSE]
   toAddP <- toAdd[,"V3", drop=FALSE]
   colnames(toAddVal) <- colnames(toAddP) <- cn
   if(exists("hsKera.raw")){
      hsKera.raw <- cbind(hsKera.raw, toAddVal)
      hsKera.pval <- cbind(hsKera.pval, toAddP)
   }else{
      hsKera.raw <- toAddVal
      hsKera.pval <- toAddP
   }
}
hsKera.d <- normalizeQuantiles(hsKera.raw)
rm(cn, f, fl, toAdd, toAddP, toAddVal)
attr(hsKera.raw, "scope") <-
   attr(hsKera.pval, "scope") <-
   attr(hsKera.d, "scope") <-
   list(
      be="Probe",
      source="GPL10558",
      organism="Homo sapiens"
   )
hsKera.p <- read.table(
   af,
   sep="\t", header=T, stringsAsFactors=FALSE,
   comment.char="", quote="", check.names=FALSE
)
hsKera.p <- hsKera.p[,c(27, 2, 12)]
colnames(hsKera.p) <- c(
   "Sample", "Description", "Treatment"
)
rownames(hsKera.p) <- hsKera.p$Sample
trgps <- c(
   "IL17"="IL17",
   "none"="Control",
   "10 ng/ml TNFα"="TNF10",
   "1 ng/ml TNFα"="TNF1",
   "IL17 + 10 ng/ml TNFα"="IL17.TNF10",
   "IL17 + 1 ng/ml TNFα"="IL17.TNF1"
)
hsKera.p$Group <- trgps[hsKera.p$Treatment]
rm(trgps)
hsKera.p <- hsKera.p[colnames(hsKera.d),]

## * DE ----
d <- hsKera.d[,which(hsKera.p$Group %in% c("Control", "IL17.TNF10"))]
p <- hsKera.p[which(hsKera.p$Group %in% c("Control", "IL17.TNF10")),]
group <- as.factor(p$Group)
design <- model.matrix(~ group + 0)
colnames(design) <- sub(
   "^group", "",
   colnames(design)
)
contrast.matrix <- makeContrasts(
   IL17.TNF10 - Control,
   levels=design
)
fit <- lmFit(
   d,
   design=design
)
fit <- contrasts.fit(fit, contrast.matrix)
fit <- eBayes(fit)
deg <- topTable(fit, number=Inf)
hsKera.DE <- deg
rm(
   af, df, dfz, eddir,
   d, p, group, design, contrast.matrix, fit, deg
)

###############################################################################@
## Preprocessing Mm Skin data ----

## * Downloading the data
eddir <- file.path(ddir, "E-GEOD-27628")
dir.create(eddir, showWarnings=FALSE)
af <- file.path(eddir, "E-GEOD-27628.sdrf.txt")
if(!file.exists(af)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-27628/E-GEOD-27628.sdrf.txt",
      destfile=af
   )
}
dfz <- file.path(eddir, "E-GEOD-27628.processed.1.zip")
if(!file.exists(dfz)){
   download.file(
      url="https://www.ebi.ac.uk/arrayexpress/files/E-GEOD-27628/E-GEOD-27628.processed.1.zip",
      destfile=dfz
   )
}
unzip(dfz, exdir=eddir)

## * Load data ----
fl <- list.files(
   eddir,
   pattern="_sample_table[.]txt$",
   full.names=TRUE
)
rm(mmSkin.raw)
for(f in fl){
   cn <- sub("_sample_table[.]txt$", "", basename(f))
   toAdd <- read.table(
      f,
      sep="\t", header=F, row.names=1, skip=2,
      stringsAsFactors = F, comment.char = "", quote="", check.names=FALSE
   )
   colnames(toAdd) <- cn
   if(exists("mmSkin.raw")){
      mmSkin.raw <- cbind(mmSkin.raw, toAdd)
   }else{
      mmSkin.raw <- toAdd
   }
}
mmSkin.d <- normalizeQuantiles(mmSkin.raw)
rm(cn, f, fl, toAdd)
attr(mmSkin.raw, "scope") <-
   attr(mmSkin.d, "scope") <-
   list(
      be="Probe",
      source="GPL1261",
      organism="Mus musculus"
   )
mmSkin.p <- read.table(
   af,
   sep="\t", header=T, stringsAsFactors=FALSE,
   comment.char="", quote="", check.names=FALSE
)
mmSkin.p <- mmSkin.p[,c(21, 3, 2, 5, 6)]
colnames(mmSkin.p) <- c(
   "Sample", "Description", "Disease", "Strain", "Skin"
)
rownames(mmSkin.p) <- mmSkin.p$Sample
mmSkin.p <- mmSkin.p[colnames(mmSkin.d),]
mmSkin.p$Disease <- ifelse(
   mmSkin.p$Disease=="Normal skin without psoriasiform phenotype",
   "Normal",
   "Psoriasis"
)

## * DE ----
d <- mmSkin.d
p <- mmSkin.p
disease <- as.factor(p$Disease)
strain <- as.factor(sub("[/]", ".", p$Strain))
skin <- as.factor(sub(" ", ".", p$Skin))
design <- model.matrix(~ disease + strain + skin + 0)
colnames(design) <- sub(
   "^disease", "",
   sub(
      "^strain", "",
      sub(
         "^skin", "",
         colnames(design)
      )
   )
)
contrast.matrix <- makeContrasts(
   Psoriasis - Normal,
   levels=design
)
fit <- lmFit(
   d,
   design=design
)
fit <- contrasts.fit(fit, contrast.matrix)
fit <- eBayes(fit)
deg <- topTable(fit, number=Inf)
mmSkin.DE <- deg
rm(
   af, df, dfz, eddir,
   d, p, disease, strain, skin, design, contrast.matrix, fit, deg
)

###############################################################################@
## Saving the data ----

save(
   hsSkin.DE, hsKera.DE, mmSkin.DE,
   file=file.path(ddir, "DEG.rda")
)

