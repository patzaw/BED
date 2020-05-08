#' Feeding BED: Set the BED version
#'
#' Not exported to avoid unintended modifications of the DB.
#' This function is used when modifying the BED content.
#'
#' @param bedInstance instance of BED to be set
#' @param bedVersion version of BED to be set
#'
setBedVersion <- function(bedInstance, bedVersion){
    bedCall(
        neo2R::cypher,
        query=neo2R::prepCql(c(
            'MERGE (n:System {name:"BED"})',
            sprintf(
               'SET n.instance = "%s"',
               bedInstance
            ),
            sprintf(
                'SET n.version = "%s"',
                bedVersion
            )
        ))
    )
}
