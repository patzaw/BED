#' Feeding BED: Load organisms in BED
#'
#' Not exported to avoid unintended modifications of the DB.
#'
#' @param d a data.frame with 2 columns named "tax_id" and "name_txt" providing
#' the taxonomic ID for each organism name
#'
loadOrganisms <- function(d){
    ##
    dColNames <- c("tax_id", "name_txt")
    if(any(!dColNames %in% colnames(d))){
        stop(paste(
            "The following columns are missing:",
            paste(setdiff(dColNames, colnames(d)), collapse=", ")
        ))
    }
    ##
    toImport <- d
    cql <- c(
        'MERGE (o:TaxID {value: row.tax_id})',
        'MERGE (on:OrganismName {value: row.name_txt, value_up:upper(row.name_txt)})',
        'MERGE (o)-[:is_named {nameClass: row.name_class}]->(on)'
    )
    bedImport(cql, toImport)
}
