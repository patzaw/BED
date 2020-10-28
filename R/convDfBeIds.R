#' Add BE ID conversion to a data frame
#'
#' @param df the data.frame to be converted
#' @param idCol the column in which ID to convert are. If NULL (default)
#' the row names are taken.
#' @param entity if TRUE returns BE instead of BEID (default: FALSE).
#' BE CAREFUL, THIS INTERNAL ID IS NOT STABLE AND CANNOT BE USED AS A REFERENCE.
#' This internal identifier is useful to avoid biases related to identifier
#' redundancy. See \url{../doc/BED.html#3_managing_identifiers}
#' @param ... params for the [convBeIds] function
#'
#' @return A data.frame with converted IDs.
#' Scope ("be", "source", "organism" and "entity" (see Arguments))
#' is provided as a named list
#' in the "scope" attributes: `attr(x, "scope")`.
#'
#' @examples \dontrun{
#' toConv <- data.frame(a=1:2, b=3:4)
#' rownames(toConv) <- c("10", "100")
#' convDfBeIds(
#'    df=toConv,
#'    from="Gene",
#'    from.source="EntrezGene",
#'    from.org="human",
#'    to.source="Ens_gene"
#' )
#' }
#'
#' @seealso [convBeIds], [convBeIdLists]
#'
#' @export
#'
convDfBeIds <- function(
   df,
   idCol=NULL,
   entity=FALSE,
   ...
){
   oriClass <- class(df)
   if(any(colnames(df) %in% c("conv.from", "conv.to"))){
      colnames(df) <- paste("x", colnames(df), sep=".")
   }
   if(length(idCol)==0){
      cols <- colnames(df)
      ct <- convBeIds(rownames(df), ...)
      df$conv.from <- as.character(rownames(df))
   }else{
      if(length(idCol)>1){
         stop("Only one idCol should be provided")
      }
      cols <- setdiff(colnames(df), idCol)
      ct <- convBeIds(df[, idCol, drop=TRUE], ...)
      df$conv.from <- as.character(df[, idCol, drop=TRUE])
      df <- df[, c(cols, "conv.from")]
   }
   scope <- attr(ct, "scope")
   ct <- ct[,c("from", ifelse(entity, "to.entity", "to"))]
   colnames(ct) <- c("from", "to")
   colnames(ct) <- paste("conv", colnames(ct), sep=".")
   df <- dplyr::inner_join(df, ct, by="conv.from")
   df <- df[, c(cols, "conv.from", "conv.to")]
   class(df) <- oriClass
   attr(df, "scope") <- c(scope, list(entity=entity))
   return(df)
}
