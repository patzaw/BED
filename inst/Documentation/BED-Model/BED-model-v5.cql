CREATE CONSTRAINT FOR (n:System) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT FOR (n:System) REQUIRE n.version IS UNIQUE;
CREATE CONSTRAINT FOR (n:TaxID) REQUIRE n.value IS UNIQUE;
CREATE CONSTRAINT FOR (n:OrganismName) REQUIRE n.value IS UNIQUE;
CREATE CONSTRAINT FOR (n:BEDB) REQUIRE n.name IS UNIQUE;
CREATE CONSTRAINT FOR (n:BEName) REQUIRE n.value IS UNIQUE;
CREATE CONSTRAINT FOR (n:BESymbol) REQUIRE n.value IS UNIQUE;
CREATE CONSTRAINT FOR (n:BEType) REQUIRE n.value IS UNIQUE;
CREATE CONSTRAINT FOR (p:Platform) REQUIRE p.name IS UNIQUE;
CREATE INDEX FOR (n:BEID) ON (n.value);
CREATE INDEX FOR (n:BEID) ON (n.database);
CREATE INDEX FOR (n:Attribute) ON (n.name);
CREATE INDEX FOR (n:GeneID) ON (n.value);
CREATE INDEX FOR (n:GeneID) ON (n.database);
CREATE INDEX FOR (n:TranscriptID) ON (n.value);
CREATE INDEX FOR (n:TranscriptID) ON (n.database);
CREATE INDEX FOR (n:PeptideID) ON (n.value);
CREATE INDEX FOR (n:PeptideID) ON (n.database);
CREATE INDEX FOR (n:ObjectID) ON (n.value);
CREATE INDEX FOR (n:ObjectID) ON (n.database);
CREATE INDEX FOR (n:ProbeID) ON (n.value);
CREATE INDEX FOR (n:ProbeID) ON (n.platform);
CREATE INDEX FOR (n:Platform) ON (n.description);
// Technical indexes
CREATE INDEX FOR (n:BESymbol) ON (n.value_up);
CREATE INDEX FOR (n:BEName) ON (n.value_up);
CREATE INDEX FOR (n:OrganismName) ON (n.value_up);
