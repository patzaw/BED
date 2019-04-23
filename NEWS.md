<!----------------------------------------------------------------------------->
## Version 1.1.6 - Release notes - 2019-04-23

### Implementation changes

   - Split the toImport file in the bedImport function before loading csv
   in neo4j ==> improve robustness and efficiency of the load
   - Separate import of nodes and import of edges to avoid neo4j eager issues
   - Add Sus scrofa support in the dumpUniprotDb function
   - Ensembl history has been adapted to avoid loop (found for some pig
   transcripts)

### Rebuild-BED.Rmd
   
   - Based on neo4j-community-3.5.4
   - Ensembl 96
   - Add GPL6887 platform
   - Add Sus scrofa (pig) support
   - Set the following cypher parameters during the building to avoid query
   replanning (https://neo4j.com/blog/cypher-write-fast-furious/):
      + --env=NEO4J_cypher_min__replan__interval=100000000ms \
      + --env=NEO4J_cypher_statistics__divergence__threshold=1 \

<!----------------------------------------------------------------------------->
## Version 1.1.5 - Release notes - 2019-01-30
   
### Methodological changes

   - Improving case insentive conversion from and to symbols

### Rebuild-BED.Rmd
   
   - Based on neo4j-community-3.4.12
   - Ensembl 95

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
