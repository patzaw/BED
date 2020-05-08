#' Show the data model of BED
#'
#' Show the shema of the BED data model.
#'
#' @export
#'
showBedDataModel <- function(){
    pkgname <- utils::packageName()
    htmlFile <- system.file(
        "Documentation", "BED-Model", "BED.html",
        package=pkgname
    )
    utils::browseURL(paste0('file://', htmlFile))
}
