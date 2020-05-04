// Lucene indexes
CALL db.index.fulltext.createNodeIndex("bename",["BESymbol", "BEName"],["value"]);
CALL db.index.fulltext.createNodeIndex("beid",["BEID", "ProbeID"],["value"]);
