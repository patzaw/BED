MERGE (gt:BEType {value:"Gene"})
MERGE (tt:BEType {value:"Transcript"})
MERGE (pt:BEType {value:"Peptide"})
MERGE (ot:BEType {value:"Object"})
MERGE (gt)-[:produces {how:"is_expressed_as"}]->(tt)
MERGE (gt)-[:produces {how:"codes_for"}]->(ot)
MERGE (tt)-[:produces {how:"is_translated_in"}]->(pt);
