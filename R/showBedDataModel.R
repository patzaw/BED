#' Show the data model of BED
#'
#' Show the shema of the BED data model.
#'
#' @importFrom utils browseURL packageName
#' @export
#'
showBedDataModel <- function(){
    pkgname <- packageName()
    htmlFile <- system.file(
        "Documentation", "BED-Model", "BED.html",
        package=pkgname
    )
    browseURL(paste0('file://', htmlFile))
}
