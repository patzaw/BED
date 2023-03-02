## ----setup, echo=FALSE--------------------------------------------------------
library(knitr)
## The following line is to avoid building errors on CRAN
knitr::opts_chunk$set(eval=Sys.getenv("USER") %in% c("pgodard"))

vn_as_png <- function(vn){
  html_file <- tempfile(fileext = ".html")
  png_file <- tempfile(fileext = ".png")
  visSave(vn, html_file)
  invisible(webshot::webshot(
    html_file, file=png_file, selector=".visNetwork", vwidth="100%"
  ))
  im <- base64enc::dataURI(file=png_file, mime="image/png")
  invisible(file.remove(c(html_file,png_file)))
  htmltools::div(
     width="100%",
     htmltools::img(src=im, alt="visNetwork", width="100%")
  )
}

## ---- eval=FALSE--------------------------------------------------------------
#  devtools::install_github("patzaw/BED")

## ---- echo=TRUE, eval=FALSE---------------------------------------------------
#  file.exists(file.path(Sys.getenv("HOME"), "R", "BED"))

## ---- message=FALSE, eval=TRUE------------------------------------------------
library(BED)

## ---- message=FALSE, eval=TRUE, echo=FALSE------------------------------------
connectToBed()

## ---- message=FALSE, eval=FALSE-----------------------------------------------
#  connectToBed(url="localhost:5454", remember=FALSE, useCache=FALSE)

## ---- message=TRUE------------------------------------------------------------
checkBedConn(verbose=TRUE)

## -----------------------------------------------------------------------------
lsBedConnections()

## ---- eval=FALSE--------------------------------------------------------------
#  showBedDataModel()

## ---- echo=FALSE, eval=TRUE---------------------------------------------------
htmltools::includeHTML(system.file(
   "Documentation", "BED-Model", "BED.html",
   package="BED"
))

## -----------------------------------------------------------------------------
results <- bedCall(
    cypher,
    query=prepCql(
       'MATCH (n:BEID)',
       'WHERE n.value IN $values',
       'RETURN DISTINCT n.value AS value, labels(n), n.database'
    ),
    parameters=list(values=c("10", "100"))
)
results

## -----------------------------------------------------------------------------
listBe()

## -----------------------------------------------------------------------------
firstCommonUpstreamBe(c("Object", "Transcript"))
firstCommonUpstreamBe(c("Peptide", "Transcript"))

## -----------------------------------------------------------------------------
listOrganisms()

## -----------------------------------------------------------------------------
getOrgNames(getTaxId("human"))

## -----------------------------------------------------------------------------
listBeIdSources(be="Transcript", organism="human")

## -----------------------------------------------------------------------------
largestBeSource(be="Transcript", organism="human", restricted=TRUE)

## -----------------------------------------------------------------------------
head(listPlatforms())
getTargetedBe("GPL570")

## -----------------------------------------------------------------------------
beids <- getBeIds(
    be="Gene", source="EntrezGene", organism="human",
    restricted=FALSE
)
dim(beids)
head(beids)

## -----------------------------------------------------------------------------
sort(table(table(beids$Gene)), decreasing = TRUE)
ambId <- sum(table(table(beids$Gene)[which(table(beids$Gene)>=10)]))

## -----------------------------------------------------------------------------
beids <- getBeIds(
    be="Gene", source="EntrezGene", organism="human",
    restricted = TRUE
)
dim(beids)

## -----------------------------------------------------------------------------
sort(table(table(beids$Gene)), decreasing = TRUE)

## -----------------------------------------------------------------------------
eid <- beids$id[which(beids$Gene %in% names(which(table(beids$Gene)>=3)))][1]
print(eid)
exploreBe(id=eid, source="EntrezGene", be="Gene") %>%
   visPhysics(solver="repulsion") %>% 
   vn_as_png()

## -----------------------------------------------------------------------------
mapt <- convBeIds(
   "MAPT", from="Gene", from.source="Symbol", from.org="human",
   to.source="Ens_gene", restricted=TRUE
)
exploreBe(
   mapt[1, "to"],
   source="Ens_gene",
   be="Gene"
) %>% 
   vn_as_png()
getBeIds(
   be="Gene", source="Ens_gene", organism="human",
   restricted=TRUE,
   attributes=listDBAttributes("Ens_gene"),
   filter=mapt$to
)

## -----------------------------------------------------------------------------
oriId <- c(
    "17237", "105886298", "76429", "80985", "230514", "66459",
    "93696", "72514", "20352", "13347", "100462961", "100043346",
    "12400", "106582", "19062", "245607", "79196", "16878", "320727",
    "230649", "66880", "66245", "103742", "320145", "140795"
)
idOrigin <- guessIdScope(oriId)
print(idOrigin$be)
print(idOrigin$source)
print(idOrigin$organism)

## -----------------------------------------------------------------------------
print(attr(idOrigin, "details"))

## -----------------------------------------------------------------------------
checkBeIds(ids=oriId, be="Gene", source="EntrezGene", organism="mouse")

## -----------------------------------------------------------------------------
checkBeIds(ids=oriId, be="Gene", source="HGNC", organism="human")

## -----------------------------------------------------------------------------
toShow <- getBeIdDescription(
    ids=oriId, be="Gene", source="EntrezGene", organism="mouse"
)
toShow$id <- paste0(
    sprintf(
        '<a href="%s" target="_blank">',
        getBeIdURL(toShow$id, "EntrezGene")
    ),
    toShow$id,
    '<a>'
)
kable(toShow, escape=FALSE, row.names=FALSE)

## -----------------------------------------------------------------------------
res <- getBeIdSymbols(
    ids=oriId, be="Gene", source="EntrezGene", organism="mouse",
    restricted=FALSE
)
head(res)

## -----------------------------------------------------------------------------
res <- getBeIdNames(
    ids=oriId, be="Gene", source="EntrezGene", organism="mouse",
    restricted=FALSE
)
head(res)

## -----------------------------------------------------------------------------
someProbes <- c(
    "238834_at", "1569297_at", "213021_at", "225480_at",
    "216016_at", "35685_at", "217969_at", "211359_s_at"
)
toShow <- getGeneDescription(
    ids=someProbes, be="Probe", source="GPL570", organism="human"
)
kable(toShow, escape=FALSE, row.names=FALSE)

## -----------------------------------------------------------------------------
getDirectProduct("ENSG00000145335", process="is_expressed_as")
getDirectProduct("ENST00000336904", process="is_translated_in")
getDirectOrigin("NM_001146055", process="is_expressed_as")

## -----------------------------------------------------------------------------
res <- convBeIds(
    ids=oriId,
    from="Gene",
    from.source="EntrezGene",
    from.org="mouse",
    to.source="Ens_gene",
    restricted=TRUE,
    prefFilter=TRUE
)
head(res)

## -----------------------------------------------------------------------------
res <- convBeIds(
    ids=oriId,
    from="Gene",
    from.source="EntrezGene",
    from.org="mouse",
    to="Peptide",
    to.source="Ens_translation",
    restricted=TRUE,
    prefFilter=TRUE
)
head(res)

## -----------------------------------------------------------------------------
res <- convBeIds(
    ids=oriId,
    from="Gene",
    from.source="EntrezGene",
    from.org="mouse",
    to="Peptide",
    to.source="Ens_translation",
    to.org="human",
    restricted=TRUE,
    prefFilter=TRUE
)
head(res)

## -----------------------------------------------------------------------------
humanEnsPeptides <- convBeIdLists(
    idList=list(a=oriId[1:5], b=oriId[-c(1:5)]),
    from="Gene",
    from.source="EntrezGene",
    from.org="mouse",
    to="Peptide",
    to.source="Ens_translation",
    to.org="human",
    restricted=TRUE,
    prefFilter=TRUE
)
unlist(lapply(humanEnsPeptides, length))
lapply(humanEnsPeptides, head)

## -----------------------------------------------------------------------------
entrezGenes <- BEIDList(
   list(a=oriId[1:5], b=oriId[-c(1:5)]),
   scope=list(be="Gene", source="EntrezGene", organism="Mus musculus"),
   metadata=data.frame(
      .lname=c("a", "b"),
      description=c("Identifiers in a", "Identifiers in b"),
      stringsAsFactors=FALSE
   )
)
entrezGenes
entrezGenes$a
ensemblGenes <- focusOnScope(entrezGenes, source="Ens_gene")
ensemblGenes$a

## -----------------------------------------------------------------------------
toConv <- data.frame(a=1:25, b=runif(25))
rownames(toConv) <- oriId
res <- convDfBeIds(
    df=toConv,
    from="Gene",
    from.source="EntrezGene",
    from.org="mouse",
    to.source="Ens_gene",
    restricted=TRUE,
    prefFilter=TRUE
)
head(res)

## -----------------------------------------------------------------------------
from.id <- "ILMN_1220595"
res <- convBeIds(
   ids=from.id, from="Probe", from.source="GPL6885", from.org="mouse",
   to="Peptide", to.source="Uniprot", to.org="human",
   prefFilter=TRUE
)
res
exploreConvPath(
   from.id=from.id, from="Probe", from.source="GPL6885",
   to.id=res$to[1], to="Peptide", to.source="Uniprot"
) %>% 
   vn_as_png()

## -----------------------------------------------------------------------------
compMap <- getBeIdSymbolTable(
   be="Gene", source="Ens_gene", organism="rat",
   restricted=FALSE
)
dim(compMap)
head(compMap)

## -----------------------------------------------------------------------------
sncaEid <- compMap[which(compMap$symbol=="Snca"),]
sncaEid
compMap[which(compMap$id %in% sncaEid$id),]

## -----------------------------------------------------------------------------
getBeIdDescription(
   sncaEid$id,
   be="Gene", source="Ens_gene", organism="rat"
)

## -----------------------------------------------------------------------------
convBeIds(
   sncaEid$id[1],
   from="Gene", from.source="Ens_gene", from.org="rat",
   to.source="Symbol"
)
convBeIds(
   sncaEid$id[2],
   from="Gene", from.source="Ens_gene", from.org="rat",
   to.source="Symbol"
)
convBeIds(
   sncaEid$id,
   from="Gene", from.source="Ens_gene", from.org="rat",
   to.source="Symbol"
)

## -----------------------------------------------------------------------------
convBeIds(
   sncaEid$id,
   from="Gene", from.source="Ens_gene", from.org="rat",
   to.source="Symbol",
   canonical=TRUE
)

## -----------------------------------------------------------------------------
convBeIds(
   "Snca",
   from="Gene", from.source="Symbol", from.org="rat",
   to.source="Ens_gene"
)

## -----------------------------------------------------------------------------
searched <- searchBeid("sv2A")
toTake <- which(searched$organism=="Homo sapiens")[1]
relIds <- geneIDsToAllScopes(
  geneids=searched$GeneID[toTake],
  source=searched$Gene_source[toTake],
  organism=searched$organism[toTake]
)

## ---- eval=FALSE--------------------------------------------------------------
#  relIds <- findBeids()

## ---- eval=FALSE--------------------------------------------------------------
#  library(shiny)
#  library(BED)
#  library(DT)
#  
#  ui <- fluidPage(
#     beidsUI("be"),
#     fluidRow(
#        column(
#           12,
#           tags$br(),
#           h3("Selected gene entities"),
#           DTOutput("result")
#        )
#     )
#  )
#  
#  server <- function(input, output){
#      found <- beidsServer("be", toGene=TRUE, multiple=TRUE, tableHeight=250)
#      output$result <- renderDT({
#         req(found())
#         toRet <- found()
#         datatable(toRet, rownames=FALSE)
#      })
#  }
#  
#  shinyApp(ui = ui, server = server)

## ---- echo=FALSE, eval=TRUE---------------------------------------------------
sessionInfo()

