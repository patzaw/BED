#' Add BE ID conversion to a data frame
#'
#' @param df the data.frame to be converted
#' @param idCol the column in which ID to convert are. If NULL (default)
#' the row names are taken.
#' @param ... params for the \code{\link{convBeIds}} function
#'
#' @return a data.frame with converted IDs
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
#' @seealso \code{\link{convBeIds}}, \code{\link{convBeIdLists}}
#'
#' @export
#'
convDfBeIds <- function(
    df,
    idCol=NULL,
    ...
){
    if(any(colnames(df) %in% c("conv.from", "conv.to"))){
        colnames(df) <- paste("x", colnames(df), sep=".")
    }
    if(length(idCol)==0){
        cols <- colnames(df)
        ct <- convBeIds(rownames(df), ...)
        df$conv.from <- rownames(df)
    }else{
        if(length(idCol)>1){
            stop("Only one idCol should be provided")
        }
        cols <- setdiff(colnames(df), idCol)
        ct <- convBeIds(df[, idCol], ...)
        df$conv.from <- df[, idCol]
        df <- df[, c(cols, "conv.from")]
    }
    ct <- ct[,c("from", "to")]
    colnames(ct) <- paste("conv", colnames(ct), sep=".")
    df <- merge(df, ct, by="conv.from")
    df <- df[, c(cols, "conv.from", "conv.to")]
    return(df)
}
