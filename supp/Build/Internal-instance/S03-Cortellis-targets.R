library(here)
wd <- here("../working")
library(BED)
connectToBed(
   url="localhost:5420",
   remember=FALSE,
   useCache=TRUE,
   importPath=file.path(wd, "neo4jImport")
)

.get_tk_headers <- do.call(function(){
   ## Choose the relevant credentials
   credentials <- readRDS("~/etc/kmt_authorization.rds")
   credentials$refresh()
   return(function(){
      if(!credentials$validate()){
         credentials$refresh()
      }
      list(
         "Authorization"=paste("Bearer", credentials$credentials$access_token)
      )
   })
}, list())
library(TKCat)
.tkcon <- chTKCat(
   "tkcat.ucb.com",
   password="",
   port=443, https=TRUE,
   extended_headers=.get_tk_headers()
)
.db_reconnect <- function(x){
   xn <- deparse(substitute(x))
   nv <- db_reconnect(x, extended_headers=.get_tk_headers())
   assign(xn, nv, envir=parent.frame(n=1))
   invisible(nv)
}

## CortellisTAR targets "Cortellis_target" coded by genes ----
ctar <- get_MDB(.tkcon, "CortellisTAR")
ctarv <- as.character(ctar$CortellisTAR_APIdump$date)
targets <- ctar$CortellisTAR_targets %>%
   filter(organism %in% listOrganisms())
prtargets <- targets %>% filter(type!="Nonspecified") %>%
   select(id, nameMain)
xref <- ctar$CortellisTAR_externalIdentifiers
entXref <- xref %>%
   filter(be=="Gene", source=="EntrezGene", targetId %in% prtargets$id)
stopifnot(all(prtargets$id %in% entXref$targetId))
allent <- getBeIds(be="Gene", source="EntrezGene", restricted=FALSE)
entXref <- entXref %>% filter(externalId %in% allent$id)

### Add Cortellis_target database ----
ddName <- "Cortellis_target"
BED:::registerBEDB(
   name=ddName,
   description="Clarivate Analytics Cortellis Targets",
   currentVersion=ctarv,
   idURL=NA
)

### Add CortellisTAR targets ----
toImport <- prtargets[, "id", drop=F]
colnames(toImport) <- "id"
BED:::loadBE(
   d=toImport, be="Object",
   dbname=ddName,
   version=NA,
   taxId=NA
)

### Add CortellisTAR target names ----
toImport <- prtargets
colnames(toImport) <- c("id", "name")
BED:::loadBENames(d=toImport, be="Object", dbname=ddName)


### Add "codes_for" edges ----
toImport <- entXref %>%
   select(externalId, targetId)
colnames(toImport) <- c("gid", "oid")
BED:::loadCodesFor(
   d=toImport,
   gdb="EntrezGene",
   odb=ddName
)

###############################################################################@

## CortellisId targets "Cortellis_idtarget" coded by genes ----
cid <- get_MDB(.tkcon, "CortellisID")
cidv <- as.character(cid$CortellisID_APIdump$date)
alltargets <- cid$CortellisID_targets
up <- cid$CortellisID_targetUniprot

### Get uniprot entrez gene identifiers ----
upEntrez <- c()
for(org in listOrganisms()){
   message(org)
   toAdd <- convBeIds(
      unique(up$uniprot),
      from="Peptide", from.source="Uniprot", from.org=org,
      to="Gene", to.source="EntrezGene",
      prefFilter=TRUE, restricted=FALSE
   )
   upEntrez <- bind_rows(
      upEntrez,
      toAdd %>%
         as_tibble() %>%
         filter(!is.na(to)) %>%
         select("uniprot"=from, "entrez"=to) %>%
         mutate(organism=!!org)
   )
}
fup <- left_join(upEntrez, up, by="uniprot", relationship = "many-to-many")

### Add Cortellis_idtarget database ----
ddName <- "Cortellis_idtarget"
BED:::registerBEDB(
   name=ddName,
   description="Clarivate Analytics Cortellis Investigational Drugs",
   currentVersion=cidv,
   idURL=NA
)

### Add CortellisID targets ----
targets <- alltargets # %>%
   # filter(id %in% fup$target)
toImport <- targets[, "id", drop=F]
colnames(toImport) <- "id"
BED:::loadBE(
   d=toImport, be="Object",
   dbname=ddName,
   version=NA,
   taxId=NA
)

### Add CortellisID target names ----
toImport <- targets
colnames(toImport) <- c("id", "name")
BED:::loadBENames(d=toImport, be="Object", dbname=ddName)

### Add "codes_for" edges ----
toImport <- fup %>%
   select(entrez, target)
colnames(toImport) <- c("gid", "oid")
BED:::loadCodesFor(
   d=toImport,
   gdb="EntrezGene",
   odb=ddName
)

## CortellisTAR ID targets "Cortellis_idtarget" related to "Cortellis_target"
idtargets <- ctar$CortellisTAR_IDTargets
idtargets2 <- cid$CortellisID_targetXref %>%
   filter(source=="Cortellis_target") %>%
   select(cortellisTAR=xref, cortellisID=targetId)
idtargets <- bind_rows(idtargets, idtargets2) %>%
   distinct(cortellisTAR, cortellisID)
toImport <- idtargets %>%
   filter(cortellisTAR %in% prtargets$id, cortellisID %in% targets$id) %>%
   select(id1=cortellisID, id2=cortellisTAR)
BED:::loadIsAssociatedTo(
   d=toImport,
   db1="Cortellis_idtarget",
   db2="Cortellis_target",
   be="Object"
)

## CortellisTAR ID targets "Cortellis_idtarget" related to "MetaBase_object"
idObjects <- cid$CortellisID_targetXref %>%
   filter(source=="MetaBase_object") %>%
   select(metabase=xref, cortellisID=targetId)
mbo <- getBeIds(be="Object", source="MetaBase_object", restricted=FALSE)
toImport <- idObjects %>%
   filter(metabase %in% mbo$id, cortellisID %in% targets$id) %>%
   select(id1=cortellisID, id2=metabase)
BED:::loadIsAssociatedTo(
   d=toImport,
   db1="Cortellis_idtarget",
   db2="MetaBase_object",
   be="Object"
)


