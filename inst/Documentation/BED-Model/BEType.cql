MERGE (gt:BEType {value:"Gene"})
MERGE (tt:BEType {value:"Transcript"})
MERGE (pt:BEType {value:"Peptide"})
MERGE (ot:BEType {value:"Object"})
CREATE UNIQUE (gt)-[:produces {how:"is_expressed_as"}]->(tt)
CREATE UNIQUE (gt)-[:produces {how:"codes_for"}]->(ot)
CREATE UNIQUE (tt)-[:produces {how:"is_translated_in"}]->(pt);

