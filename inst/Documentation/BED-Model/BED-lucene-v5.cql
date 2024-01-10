// Lucene indexes
CREATE FULLTEXT INDEX bename FOR (n:BESymbol|BEName) ON EACH [n.value];
CREATE FULLTEXT INDEX beid FOR (n:BEID|ProbeID) ON EACH [n.value];
