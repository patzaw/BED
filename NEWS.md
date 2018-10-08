<!----------------------------------------------------------------------------->
## Version 1.1.4 - notes

   - Notes about converting from and to gene symbols in the BED vignette.
   - Simplification of the feeding procedure based on docker (see README.md)

<!----------------------------------------------------------------------------->
## Version 1.1.3 - notes

### Bug fixes

   - Avoid duplicated lines returned by convBeIds when converting from Symbols.

<!----------------------------------------------------------------------------->
## Version 1.1.2 - Release notes - 2018-07-20
   
### Methodological changes

   - More accurate ortholog mapping by avoiding the use of deprecated gene
   identifiers in the convBeIds function.
   
### Vignettes
   
   - BED: based on bed-ucb-human:2018.07.20
   (https://hub.docker.com/r/patzaw/bed-ucb-human/)

### Rebuild-BED.Rmd
   
   - Based on neo4j-community-3.4.4
   - Ensembl 93

### Bug fixes

   - searchId: focusing on one or several BE
