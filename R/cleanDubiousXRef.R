#' Identify and remove dubious cross-references
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a cross-reference data.frame with 2 columns.
#' @param strict if TRUE (default), the function returns only unambiguous
#' mappings
#'
#' @return This function returns d without dubious cross-references.
#' Issues are reported in attr(d, "issues").
#'
#' @importFrom dplyr filter group_by ungroup mutate summarise left_join select bind_rows
#' @export
cleanDubiousXRef <- function(d, strict=TRUE){

   ############################################################################@
   ## Helpers ----
   # splitByCluster <- function(ref, exref){
   #    toRet <- list()
   #    toTake <- unique(ref$id1)
   #    while(length(toTake)>0){
   #       taken <- toTake[1]
   #       toAdd <- getClustId(taken, exref, ref)
   #       toTake <- setdiff(toTake, toAdd$id1)
   #       toAdd <- list(toAdd)
   #       names(toAdd) <- taken
   #       toRet <- c(toRet, toAdd)
   #    }
   #    return(toRet)
   # }
   # getClustId <- function(id, exref, ref=exref){
   #    direct <- exref[which(exref$id1==id | exref$id2==id),]
   #    indirect <- exref[
   #       which(
   #          exref$id1 %in% direct$id1 |
   #             exref$id2 %in% direct$id2
   #       ),
   #    ]
   #    while(!identical(direct, indirect)){
   #       direct <- indirect
   #       indirect <- exref[
   #          which(
   #             exref$id1 %in% direct$id1 |
   #                exref$id2 %in% direct$id2
   #          ),
   #       ]
   #    }
   #    toRet <- ref[which(
   #       ref$xrid %in% indirect$xrid
   #    ),]
   #    return(toRet)
   # }

   ############################################################################@
   ## Check input ----
   stopifnot(ncol(d)==2)
   ocolnames <- colnames(d)
   colnames(d) <- c("id1", "id2")

   ############################################################################@
   ## Preprocessing ----
   dup1 <- group_by(d, id1)
   dup1 <- ungroup(summarise(dup1, l2=length(id2)))
   dup2 <- group_by(d, id2)
   dup2 <- ungroup(summarise(dup2, l1=length(id1)))
   exref <- d
   exref <- left_join(exref, dup1, by="id1")
   exref <- left_join(exref, dup2, by="id2")
   exref$xrid <- 1:nrow(d)

   ############################################################################@
   ## Candidate issues ----
   if(strict){
      nonIssues <-  filter(exref, l1==1 & l2==1)
      nonIssues <- as.data.frame(select(nonIssues, id1, id2))
      colnames(nonIssues) <- ocolnames
      toRet <- nonIssues
      return(toRet)
   }else{
      nonIssues <-  filter(exref, !l1>1 | !l2>1)
      candidateIssues <- filter(exref, l1>1 & l2>1)

      ## _+ Examining candidate issues ----
      issues <- filter(
         candidateIssues,
         id1 %in% nonIssues$id1 | id2 %in% nonIssues$id2
      )
      undecided <- filter(
         candidateIssues,
         !id1 %in% nonIssues$id1 & !id2 %in% nonIssues$id2
      )
      exrefTmp <- exref
      while(!identical(exrefTmp, undecided)){
         exrefTmp <- select(undecided, -l2, -l1)
         dup1 <- group_by(exrefTmp, id1)
         dup1 <- ungroup(summarise(dup1, l2=length(id2)))
         dup2 <- group_by(exrefTmp, id2)
         dup2 <- ungroup(summarise(dup2, l1=length(id1)))
         exrefTmp <- left_join(exrefTmp, dup1, by="id1")
         exrefTmp <- left_join(exrefTmp, dup2, by="id2")
         ##
         nonIssueToAdd <-  filter(exrefTmp, !l1>1 | !l2>1)
         nonIssues <- bind_rows(nonIssues, nonIssueToAdd)
         candidateIssuesTmp <- filter(exrefTmp, l1>1 & l2>1)
         issuesToAdd <- filter(
            candidateIssuesTmp,
            id1 %in% nonIssueToAdd$id1 | id2 %in% nonIssueToAdd$id2
         )
         issues <- bind_rows(issues, issuesToAdd)
         undecided <- filter(
            candidateIssuesTmp,
            !id1 %in% nonIssueToAdd$id1 & !id2 %in% nonIssueToAdd$id2
         )
      }

      # splUndecided <- splitByCluster(undecided, exref)
      # splUndecided.OK <- unlist(lapply(
      #    splUndecided,
      #    function(x){
      #       l1 <- unique(x$l1)
      #       l2 <- unique(x$l2)
      #       if(length(l1)>1 | length(l2)>1){
      #          return(FALSE)
      #       }else{
      #          if(l2==length(unique(x$id2)) & l1==length(unique(x=x$id1))){
      #             return(TRUE)
      #          }else{
      #             return(FALSE)
      #          }
      #       }
      #    }
      # ))
      # if(!all(splUndecided.OK)){
      #    warning("Review undecided")
      # }

      nonIssues <- bind_rows(nonIssues, undecided)
      nonIssues <- as.data.frame(select(nonIssues, id1, id2))
      issues <- as.data.frame(select(issues, id1, id2))
      colnames(nonIssues) <- colnames(issues) <- ocolnames

      toRet <- nonIssues
      attr(toRet, "issues") <- issues
      return(toRet)
   }

}
