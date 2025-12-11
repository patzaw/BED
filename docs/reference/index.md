# Package index

## All functions

- [`BED`](https://patzaw.github.io/BED/reference/BED.md) : Biological
  Entity Dictionary (BED)
- [`BEIDList()`](https://patzaw.github.io/BED/reference/BEIDList.md) :
  Create a BEIDList
- [`BEIDs()`](https://patzaw.github.io/BED/reference/BEIDs.md) : Get the
  BEIDs from an object
- [`beIDsToAllScopes()`](https://patzaw.github.io/BED/reference/beIDsToAllScopes.md)
  : Find all BEID and ProbeID corresponding to a BE
- [`bedCall()`](https://patzaw.github.io/BED/reference/bedCall.md) :
  Call a function on the BED graph
- [`bedImport()`](https://patzaw.github.io/BED/reference/bedImport.md) :
  Feeding BED: Imports a data.frame in the BED graph database
- [`beidsServer()`](https://patzaw.github.io/BED/reference/beidsServer.md)
  [`beidsUI()`](https://patzaw.github.io/BED/reference/beidsServer.md) :
  Shiny module for searching BEIDs
- [`cacheBedCall()`](https://patzaw.github.io/BED/reference/cacheBedCall.md)
  : Cached neo4j call
- [`cacheBedResult()`](https://patzaw.github.io/BED/reference/cacheBedResult.md)
  : Put a BED query result in cache
- [`checkBeIds()`](https://patzaw.github.io/BED/reference/checkBeIds.md)
  : Check biological entities (BE) identifiers
- [`checkBedCache()`](https://patzaw.github.io/BED/reference/checkBedCache.md)
  : Check BED cache
- [`checkBedConn()`](https://patzaw.github.io/BED/reference/checkBedConn.md)
  : Check if there is a connection to a BED database
- [`cleanDubiousXRef()`](https://patzaw.github.io/BED/reference/cleanDubiousXRef.md)
  : Identify and remove dubious cross-references
- [`clearBedCache()`](https://patzaw.github.io/BED/reference/clearBedCache.md)
  : Clear the BED cache SQLite database
- [`compareBedInstances()`](https://patzaw.github.io/BED/reference/compareBedInstances.md)
  : Compare 2 BED database instances
- [`connectToBed()`](https://patzaw.github.io/BED/reference/connectToBed.md)
  : Connect to a neo4j BED database
- [`convBeIdLists()`](https://patzaw.github.io/BED/reference/convBeIdLists.md)
  : Converts lists of BE IDs
- [`convBeIds()`](https://patzaw.github.io/BED/reference/convBeIds.md) :
  Converts BE IDs
- [`convDfBeIds()`](https://patzaw.github.io/BED/reference/convDfBeIds.md)
  : Add BE ID conversion to a data frame
- [`dumpEnsCore()`](https://patzaw.github.io/BED/reference/dumpEnsCore.md)
  : Feeding BED: Dump table from the Ensembl core database
- [`dumpNcbiDb()`](https://patzaw.github.io/BED/reference/dumpNcbiDb.md)
  : Feeding BED: Dump tables from the NCBI gene DATA
- [`dumpNcbiTax()`](https://patzaw.github.io/BED/reference/dumpNcbiTax.md)
  : Feeding BED: Dump tables with taxonomic information from NCBI
- [`dumpUniprotDb()`](https://patzaw.github.io/BED/reference/dumpUniprotDb.md)
  : Feeding BED: Dump and preprocess flat data files from Uniprot
- [`exploreBe()`](https://patzaw.github.io/BED/reference/exploreBe.md) :
  Explore BE identifiers
- [`exploreConvPath()`](https://patzaw.github.io/BED/reference/exploreConvPath.md)
  : Explore the shortest convertion path between two identifiers
- [`filterByBEID()`](https://patzaw.github.io/BED/reference/filterByBEID.md)
  : Filter an object to keep only a set of BEIDs
- [`findBe()`](https://patzaw.github.io/BED/reference/findBe.md) : Find
  Biological Entity
- [`findBeids()`](https://patzaw.github.io/BED/reference/findBeids.md) :
  Find Biological Entity identifiers
- [`firstCommonUpstreamBe()`](https://patzaw.github.io/BED/reference/firstCommonUpstreamBe.md)
  : First common upstream BE
- [`focusOnScope(`*`<BEIDList>`*`)`](https://patzaw.github.io/BED/reference/focusOnScope.BEIDList.md)
  : Convert a BEIDList object in a specific identifier (BEID) scope
- [`focusOnScope()`](https://patzaw.github.io/BED/reference/focusOnScope.md)
  : Focus a BE related object on a specific identifier (BEID) scope
- [`forgetBedConnection()`](https://patzaw.github.io/BED/reference/forgetBedConnection.md)
  : Forget a BED connection
- [`genBePath()`](https://patzaw.github.io/BED/reference/genBePath.md) :
  Construct CQL sub-query to map 2 biological entity
- [`genProbePath()`](https://patzaw.github.io/BED/reference/genProbePath.md)
  : Identify the biological entity (BE) targeted by probes and construct
  the CQL sub-query to map probes to the BE
- [`geneIDsToAllScopes()`](https://patzaw.github.io/BED/reference/geneIDsToAllScopes.md)
  : Find all GeneID, ObjectID, TranscriptID, PeptideID and ProbeID
  corresponding to a Gene in any organism
- [`getAllBeIdSources()`](https://patzaw.github.io/BED/reference/getAllBeIdSources.md)
  : List all the source databases of BE identifiers whatever the BE type
- [`getBeIdConvTable()`](https://patzaw.github.io/BED/reference/getBeIdConvTable.md)
  : Get a conversion table between biological entity (BE) identifiers
- [`getBeIdDescription()`](https://patzaw.github.io/BED/reference/getBeIdDescription.md)
  : Get description of Biological Entity identifiers
- [`getBeIdNameTable()`](https://patzaw.github.io/BED/reference/getBeIdNameTable.md)
  : Get a table of biological entity (BE) identifiers and names
- [`getBeIdNames()`](https://patzaw.github.io/BED/reference/getBeIdNames.md)
  : Get names of Biological Entity identifiers
- [`getBeIdSymbolTable()`](https://patzaw.github.io/BED/reference/getBeIdSymbolTable.md)
  : Get a table of biological entity (BE) identifiers and symbols
- [`getBeIdSymbols()`](https://patzaw.github.io/BED/reference/getBeIdSymbols.md)
  : Get symbols of Biological Entity identifiers
- [`getBeIdURL()`](https://patzaw.github.io/BED/reference/getBeIdURL.md)
  : Get reference URLs for BE IDs
- [`getBeIds()`](https://patzaw.github.io/BED/reference/getBeIds.md) :
  Get biological entities identifiers
- [`getDirectOrigin()`](https://patzaw.github.io/BED/reference/getDirectOrigin.md)
  : Get the direct origin of BE identifiers
- [`getDirectProduct()`](https://patzaw.github.io/BED/reference/getDirectProduct.md)
  : Get the direct product of BE identifiers
- [`getEnsemblGeneIds()`](https://patzaw.github.io/BED/reference/getEnsemblGeneIds.md)
  : Feeding BED: Download Ensembl DB and load gene information in BED
- [`getEnsemblPeptideIds()`](https://patzaw.github.io/BED/reference/getEnsemblPeptideIds.md)
  : Feeding BED: Download Ensembl DB and load peptide information in BED
- [`getEnsemblTranscriptIds()`](https://patzaw.github.io/BED/reference/getEnsemblTranscriptIds.md)
  : Feeding BED: Download Ensembl DB and load transcript information in
  BED
- [`getGeneDescription()`](https://patzaw.github.io/BED/reference/getGeneDescription.md)
  : Get description of genes corresponding to Biological Entity
  identifiers
- [`getHomTable()`](https://patzaw.github.io/BED/reference/getHomTable.md)
  : Get gene homologs between 2 organisms
- [`getNcbiGeneTransPep()`](https://patzaw.github.io/BED/reference/getNcbiGeneTransPep.md)
  : Feeding BED: Download NCBI gene DATA and load gene, transcript and
  peptide information in BED
- [`getOrgNames()`](https://patzaw.github.io/BED/reference/getOrgNames.md)
  : Get organism names from taxonomy IDs
- [`getRelevantIds()`](https://patzaw.github.io/BED/reference/getRelevantIds.md)
  : Get relevant IDs for a formerly identified BE in a context of
  interest
- [`getTargetedBe()`](https://patzaw.github.io/BED/reference/getTargetedBe.md)
  : Identify the biological entity (BE) targeted by probes
- [`getTaxId()`](https://patzaw.github.io/BED/reference/getTaxId.md) :
  Get taxonomy ID of an organism name
- [`getUniprot()`](https://patzaw.github.io/BED/reference/getUniprot.md)
  : Feeding BED: Download Uniprot information in BED
- [`guessIdScope()`](https://patzaw.github.io/BED/reference/guessIdScope.md)
  [`guessIdOrigin()`](https://patzaw.github.io/BED/reference/guessIdScope.md)
  : Guess biological entity (BE), database source and organism of a
  vector of identifiers.
- [`identicalScopes()`](https://patzaw.github.io/BED/reference/identicalScopes.md)
  : Check if two objects have the same BEID scope
- [`is.BEIDList()`](https://patzaw.github.io/BED/reference/is.BEIDList.md)
  : Check if the provided object is a BEIDList
- [`largestBeSource()`](https://patzaw.github.io/BED/reference/largestBeSource.md)
  : Autoselect source of biological entity identifiers
- [`listBe()`](https://patzaw.github.io/BED/reference/listBe.md) : Lists
  all the biological entities (BE) available in the BED database
- [`listBeIdSources()`](https://patzaw.github.io/BED/reference/listBeIdSources.md)
  : Lists all the databases taken into account in the BED database for a
  biological entity (BE)
- [`listDBAttributes()`](https://patzaw.github.io/BED/reference/listDBAttributes.md)
  : List all attributes provided by a BEDB
- [`listOrganisms()`](https://patzaw.github.io/BED/reference/listOrganisms.md)
  : Lists all the organisms available in the BED database
- [`listPlatforms()`](https://patzaw.github.io/BED/reference/listPlatforms.md)
  : Lists all the probe platforms available in the BED database
- [`loadBE()`](https://patzaw.github.io/BED/reference/loadBE.md) :
  Feeding BED: Load biological entities in BED
- [`loadBENames()`](https://patzaw.github.io/BED/reference/loadBENames.md)
  : Feeding BED: Load names associated to BEIDs
- [`loadBESymbols()`](https://patzaw.github.io/BED/reference/loadBESymbols.md)
  : Feeding BED: Load symbols associated to BEIDs
- [`loadBEVersion()`](https://patzaw.github.io/BED/reference/loadBEVersion.md)
  : Feeding BED: Load biological entities in BED with information about
  DB version
- [`loadBeAttribute()`](https://patzaw.github.io/BED/reference/loadBeAttribute.md)
  : Feeding BED: Load attributes for biological entities in BED
- [`loadBedModel()`](https://patzaw.github.io/BED/reference/loadBedModel.md)
  : Feeding BED: Load BED data model in neo4j
- [`loadBedOtherIndexes()`](https://patzaw.github.io/BED/reference/loadBedOtherIndexes.md)
  : Feeding BED: Load additional indexes in neo4j
- [`loadBedResult()`](https://patzaw.github.io/BED/reference/loadBedResult.md)
  : Get a BED query result from cache
- [`loadCodesFor()`](https://patzaw.github.io/BED/reference/loadCodesFor.md)
  : Feeding BED: Load correspondance between genes and objects as coding
  events
- [`loadCorrespondsTo()`](https://patzaw.github.io/BED/reference/loadCorrespondsTo.md)
  : Feeding BED: Load correspondances between BE IDs
- [`loadHistory()`](https://patzaw.github.io/BED/reference/loadHistory.md)
  : Feeding BED: Load history of BEIDs
- [`loadIsAssociatedTo()`](https://patzaw.github.io/BED/reference/loadIsAssociatedTo.md)
  : Feeding BED: Load BE ID associations
- [`loadIsExpressedAs()`](https://patzaw.github.io/BED/reference/loadIsExpressedAs.md)
  : Feeding BED: Load correspondance between genes and transcripts as
  expression events
- [`loadIsHomologOf()`](https://patzaw.github.io/BED/reference/loadIsHomologOf.md)
  : Feeding BED: Load homology between BE IDs
- [`loadIsTranslatedIn()`](https://patzaw.github.io/BED/reference/loadIsTranslatedIn.md)
  : Feeding BED: Load correspondance between transcripts and peptides as
  translation events
- [`loadLuceneIndexes()`](https://patzaw.github.io/BED/reference/loadLuceneIndexes.md)
  : Feeding BED: Create Lucene indexes in neo4j
- [`loadNCBIEntrezGOFunctions()`](https://patzaw.github.io/BED/reference/loadNCBIEntrezGOFunctions.md)
  : Feeding BED: Load in BED GO functions associated to Entrez gene IDs
  from NCBI
- [`loadNcbiTax()`](https://patzaw.github.io/BED/reference/loadNcbiTax.md)
  : Feeding BED: Load taxonomic information from NCBI
- [`loadOrganisms()`](https://patzaw.github.io/BED/reference/loadOrganisms.md)
  : Feeding BED: Load organisms in BED
- [`loadPlf()`](https://patzaw.github.io/BED/reference/loadPlf.md) :
  Feeding BED: Load a probes platform
- [`loadProbes()`](https://patzaw.github.io/BED/reference/loadProbes.md)
  : Feeding BED: Load probes targeting BE IDs
- [`lsBedCache()`](https://patzaw.github.io/BED/reference/lsBedCache.md)
  : List all the BED queries in cache and the total size of the cache
- [`lsBedConnections()`](https://patzaw.github.io/BED/reference/lsBedConnections.md)
  : List all registered BED connection
- [`` `metadata<-`() ``](https://patzaw.github.io/BED/reference/metadata-set.md)
  : Set object metadata
- [`metadata()`](https://patzaw.github.io/BED/reference/metadata.md) :
  Get object metadata
- [`registerBEDB()`](https://patzaw.github.io/BED/reference/registerBEDB.md)
  : Feeding BED: Register a database of biological entities in BED DB
- [`scope()`](https://patzaw.github.io/BED/reference/scope.md) : Get the
  BEID scope of an object
- [`scopes()`](https://patzaw.github.io/BED/reference/scopes.md) : Get
  the BEID scopes of an object
- [`searchBeid()`](https://patzaw.github.io/BED/reference/searchBeid.md)
  : Search a BEID
- [`searchId()`](https://patzaw.github.io/BED/reference/searchId.md) :
  Search identifier, symbol or name information
- [`setBedVersion()`](https://patzaw.github.io/BED/reference/setBedVersion.md)
  : Feeding BED: Set the BED version
- [`showBedDataModel()`](https://patzaw.github.io/BED/reference/showBedDataModel.md)
  : Show the data model of BED
