<!----------------------------------------------------------------------------->
## Version 1.4.8

### Neo4j changes

   - `connectToBed()` supports the .opts parameter of `RCurl::curlPerform()`.


<!----------------------------------------------------------------------------->
## Version 1.4.7

### Neo4j changes

   - "CREATE UNIQUE" replaced by "MERGE" in neo4j queries
   
<!----------------------------------------------------------------------------->
## Version 1.4.6

### Bug fix

   - Suppress wrong warning in `listBeIdSources()`

<!----------------------------------------------------------------------------->
## Version 1.4.5

### Improvements

   - Use https protocol for getting NCBI data
   - `dumpNcbiTax`: using the zip archive instead of the tar.gz because
   of internal issue with firewall.
   - Correct canonical products from Ensembl

<!----------------------------------------------------------------------------->
## Version 1.4.4

### Improvements
 
   - `convBeIds()` and `getBeIdConvTable()` have an additional parameter
   "canonical" to only keep canonical symbols of BE when converting from or
   to symbols.

### Rebuild BED

   - `dumpUniprotDb()` uses less memory

<!----------------------------------------------------------------------------->
## Version 1.4.3

### Complying with CRAN policies

   - Software names in single quotes ('Neo4j' and 'Docker') in title and
   description fields of the DESCRIPTION file.
   - Reference added in the description field of the DESCRIPTION file.
   - Link to the 'Docker' image of the 'Neo4j' database added in the
   description field of the DESCRIPTION file.
   - Author and contribution declared in the Authors@R field of the
   DESCRIPTION file.
   - Functions `forgetBedConnection()`, `dumpEnsCore()`, `dumpNcbiDb()`,
   `dumpNcbiTax()`, `dumpUniprotDb()`, `getEnsemblGeneIds()`,
   `getEnsemblPeptideIds()`, `getEnsemblTranscriptIds()`,
   `getNcbiGeneTransPep()`, `getUniprot()`,
   `loadNCBIEntrezGOFunctions()`,  and `loadNcbiTax()`
   functions do not write anymore by default in the user's home file space.
   - As explained in the documentation and in code comments, query results
   are automatically written on user's home file space if and only if the
   cache parameter has been set to TRUE when calling the `connectToBed()`
   function (by default this parameter is set to FALSE). 


<!----------------------------------------------------------------------------->
## Version 1.4.2

### Bug fixes

   - Correction of a bug when no data is returned by listBeIdSources
   - Type correction before inner_join when getting data

<!----------------------------------------------------------------------------->
## Version 1.4.0

### New features

   - Shiny module: `beidsServer()` and `beidsUI()` functions
   - New Shiny gadget (RStudio addin): `findBeids()`
   - `guessIdOrigin()` (still available) has been renamed `guessIdScope()`.
   It takes into account user input to guess the identifiers scope.
   - The scope of the identifiers to convert or to explore is automatically
   guessed when not provided by the user. It is still recommended to
   provide them when they are known but this feature could help for
   exploratory session.
   - Find all identifiers in all scopes corresponding to BE:
      - `beIDsToAllScopes()` (more specific than `geneIDsToAllScopes()`)

### Implementation changes

   - By default the system does not remember connections for policy reasons.
   - By default the system does not use cache for policy reasons. However,
   it is recommended to set it to TRUE when connecting to improve the speed
   of recurent queries.
   - `merge()` calls have been replaced by `dplyr::inner_join()`.
   - Import statements have been replaced as much as possible by
   explicit `::` calls.

<!----------------------------------------------------------------------------->
## Version 1.3.0

### New features

   - Use of lucene indexes for fast and flexible searches of BE:
      - `searchBeid()`
   - Find all identifiers in all scopes corresponding to genes:
      - `geneIDsToAllScopes()`

### Implementation changes

   - Simplification of queries for getting gene descriptions
   
### Rebuild-BED.Rmd
   
   - Not in the final package anymore
   - Ensembl 100
   - Based on neo4j-community-3.5.17
   - GO molecular functions are not included anymore
   (more relevant tools should be used for that purpose)

<!----------------------------------------------------------------------------->
## Version 1.2.4

### Implementation changes

   - Correct a bug when chosing a be in searchId
   - Avoid the application to crash when there is no running neo4j instance
   (This bug appeared with version 2 of neo2R)

<!----------------------------------------------------------------------------->
## Version 1.2.3

### Rebuild-BED.Rmd
   
   - Ensembl 99
   - Based on neo4j-community-3.5.14
   - NCBI does not support mapping to unigene and vega anymore.
   Unigene and Vega identifiers are not available anymore in BED as well.

### Implementation changes

   - Prepopulate nodes with a subset and
   use 'CALL db.resampleOutdatedIndexes();'
   to speed up the feeding process.

<!----------------------------------------------------------------------------->
## Version 1.2.2

### Rebuild-BED.Rmd
   
   - Ensembl 98
   - Based on neo4j-community-3.5.11
   - Because of a few (a very small number but quite annoying) dubious mapping
   with EntrezGene identifier, only unambigous mapping from Ensembl have been
   conserved. Relevant ambigous mapping be rescued by mapping from the NCBI
   and to other reference database such as HGNC, MGI or RGD.
   The cleanDubiousXRef() has been updated to this end
   Examples:
      + https://www.ensembl.org/Homo_sapiens/Gene/Matches?g=ENSG00000120088
      
   
<!----------------------------------------------------------------------------->
## Version 1.2.1

### Implementation changes

   - Improving mapping function for supporting difficult history
   of Zebrafish Ensembl identifiers

<!----------------------------------------------------------------------------->
## Version 1.2.0

### Implementation changes

   - cleanDubiousXRef() function applied to NCBI gene cross-references
   from Ensembl

### Rebuild-BED.Rmd
   
   - Based on neo4j-community-3.5.9
   - Add Danio rerio (zebrafish) support

<!----------------------------------------------------------------------------->
## Version 1.1.9

### Implementation changes

   - Correction of findBe() result display
   - Correction of bug in getBeIds() and getRelevantIds()
   - Implement BEIDList class

<!----------------------------------------------------------------------------->
## Version 1.1.8 - Release notes - 2019-07-29

### Implementation changes

   - Correction of how Ensembl data files are pre-processed because of
   the apparition of "carriage return" (\r\n) characters.
   - Give write rights on the neo4j database before copying it in the docker
   image. 

### Rebuild-BED.Rmd
   
   - Based on neo4j-community-3.5.7
   - Ensembl 97

<!----------------------------------------------------------------------------->
## Version 1.1.7 - Release notes - 2019-05-08

### Implementation changes

   - When associating one id to another, the BE identified by the first id
   is deleted after that its production edges have been transferred.
   After this operation all id "corresponding_to" the first id do not
   directly identify any BE as they should be supposed to do. Thus,
   it's not recommended to associate such ID to others.

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
