#' @title Biological Entity Dictionary (BED)
#' @author Patrice Godard
#' @name BED
#' @description An interface for the neo4j database providing
#' mapping between different identifiers of biological entities.
#' This Biological Entity Dictionary (BED)
#' has been developed to address three main challenges.
#' The first one is related to the completeness of identifier mappings.
#' Indeed, direct mapping information provided by the different systems
#' are not always complete and can be enriched by mappings provided by other
#' resources.
#' More interestingly, direct mappings not identified by any of these
#' resources can be indirectly inferred by using mappings to a third reference.
#' For example, many human Ensembl gene ID are not directly mapped to any
#' Entrez gene ID but such mappings can be inferred using respective mappings
#' to HGNC ID. The second challenge is related to the mapping of deprecated
#' identifiers. Indeed, entity identifiers can change from one resource
#' release to another. The identifier history is provided by some resources,
#' such as Ensembl or the NCBI, but it is generally not used by mapping tools.
#' The third challenge is related to the automation of the mapping process
#' according to the relationships between the biological entities of interest.
#' Indeed, mapping between gene and protein ID scopes should not be done
#' the same way than between two scopes regarding gene ID.
#' Also, converting identifiers from different organisms should be possible
#' using gene orthologs information.
#'
#' - [Vignette](../doc/BED.html)
#' - Available database instance: <https://github.com/patzaw/BED#bed-database-instance-available-as-a-docker-image>
#' - Building a database instance: <https://github.com/patzaw/BED#build-a-bed-database-instance>
#' - Repository: <https://github.com/patzaw/BED>
#' - Bug reports: <https://github.com/patzaw/BED/issues>
#'
#' @import utils neo2R dplyr visNetwork stringr
NULL
