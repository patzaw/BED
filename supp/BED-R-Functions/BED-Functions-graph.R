library(mvbutils)
library(reshape2)
library(BED)
bf <- foodweb(where=asNamespace("BED"), plotting=FALSE)
bfp <- foodweb(where="package:BED", plotting=FALSE)
pubFun <- names(bfp$level)
bfLev <- bf$level
bf <- bf$funmat
bf <- melt(bf)
bf <- bf[which(bf$value==1), -3]
colnames(bf) <- c("from", "to")
n <- data.frame(id=sort(union(bf$from, bf$to)), stringsAsFactors=F)
n$label <- n$title <- n$id
n$level <- round(bfLev[n$id])
n$group <- ifelse(n$id %in% pubFun, "Public", "Private")
visNetwork(nodes=n, edges=bf) %>%
   visEdges(
      arrows =list(to = list(enabled = TRUE))
   ) %>%
   visGroups(
      groupname="Public",
      color=list(background="#ef6548", border="#7f0000", highlight="#7f0000"),
      shape="dot"
   ) %>%
   visGroups(
      groupname="Private",
      color=list(background="#4eb3d3", border="#084081", highlight="#084081"),
      shape="dot"
   ) %>%
   visOptions(
      highlightNearest = TRUE,
      nodesIdSelection = TRUE
   ) %>%
   visHierarchicalLayout(
      enabled=TRUE,
      sortMethod="directed",
      direction="DU"
   ) %>%
   visPhysics(enabled=FALSE) %>%
   visLegend()

