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
   dup1 <- dplyr::group_by(d, .data$id1)
   dup1 <- dplyr::ungroup(dplyr::summarise(dup1, l2=length(.data$id2)))
   dup2 <- dplyr::group_by(d, .data$id2)
   dup2 <- dplyr::ungroup(dplyr::summarise(dup2, l1=length(.data$id1)))
   exref <- d
   exref <- dplyr::left_join(exref, dup1, by="id1")
   exref <- dplyr::left_join(exref, dup2, by="id2")
   exref$xrid <- 1:nrow(d)

   ############################################################################@
   ## Candidate issues ----
   if(strict){
      nonIssues <-  dplyr::filter(exref, .data$l1==1 & .data$l2==1)
      nonIssues <- as.data.frame(dplyr::select(nonIssues, "id1", "id2"))
      colnames(nonIssues) <- ocolnames
      toRet <- nonIssues
      return(toRet)
   }else{
      nonIssues <- dplyr::filter(exref, !.data$l1>1 | !.data$l2>1)
      candidateIssues <- dplyr::filter(exref, .data$l1>1 & .data$l2>1)

      ## _+ Examining candidate issues ----
      issues <- dplyr::filter(
         candidateIssues,
         .data$id1 %in% nonIssues$id1 | .data$id2 %in% nonIssues$id2
      )
      undecided <- dplyr::filter(
         candidateIssues,
         !.data$id1 %in% nonIssues$id1 & !.data$id2 %in% nonIssues$id2
      )
      exrefTmp <- exref
      .data <- NULL
      while(!identical(exrefTmp, undecided)){
         exrefTmp <- dplyr::select(undecided, -"l2", -"l1")
         dup1 <- dplyr::group_by(exrefTmp, .data$id1)
         dup1 <- dplyr::ungroup(dplyr::summarise(dup1, l2=length(.data$id2)))
         dup2 <- dplyr::group_by(exrefTmp, .data$id2)
         dup2 <- dplyr::ungroup(dplyr::summarise(dup2, l1=length(.data$id1)))
         exrefTmp <- dplyr::left_join(exrefTmp, dup1, by="id1")
         exrefTmp <- dplyr::left_join(exrefTmp, dup2, by="id2")
         ##
         nonIssueToAdd <-  dplyr::filter(exrefTmp, !.data$l1>1 | !.data$l2>1)
         nonIssues <- dplyr::bind_rows(nonIssues, nonIssueToAdd)
         candidateIssuesTmp <- dplyr::filter(exrefTmp, .data$l1>1 & .data$l2>1)
         issuesToAdd <- dplyr::filter(
            candidateIssuesTmp,
            .data$id1 %in% nonIssueToAdd$id1 | .data$id2 %in% nonIssueToAdd$id2
         )
         issues <- dplyr::bind_rows(issues, issuesToAdd)
         undecided <- dplyr::filter(
            candidateIssuesTmp,
            !.data$id1 %in% nonIssueToAdd$id1 &
               !.data$id2 %in% nonIssueToAdd$id2
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

      nonIssues <- dplyr::bind_rows(nonIssues, undecided)
      nonIssues <- as.data.frame(dplyr::select(nonIssues, "id1", "id2"))
      issues <- as.data.frame(dplyr::select(issues, "id1", "id2"))
      colnames(nonIssues) <- colnames(issues) <- ocolnames

      toRet <- nonIssues
      attr(toRet, "issues") <- issues
      return(toRet)
   }

}
