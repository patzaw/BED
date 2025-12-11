# Find all GeneID, ObjectID, TranscriptID, PeptideID and ProbeID corresponding to a Gene in any organism

Find all GeneID, ObjectID, TranscriptID, PeptideID and ProbeID
corresponding to a Gene in any organism

## Usage

``` r
geneIDsToAllScopes(
  geneids,
  source,
  organism,
  entities = NULL,
  orthologs = TRUE,
  canonical_symbols = TRUE
)
```

## Arguments

- geneids:

  a character vector of gene identifiers

- source:

  the source of gene identifiers. **Guessed if not provided**

- organism:

  the gene organism. **Guessed if not provided**

- entities:

  a numeric vector of gene entity. If NULL (default), geneids, source
  and organism arguments are used to identify genes. Be carefull when
  using entities as these identifiers are not stable.

- orthologs:

  return identifiers from orthologs

- canonical_symbols:

  return only canonical symbols (default: TRUE).

## Value

A data.frame with the following fields:

- **value**: the identifier

- **preferred**: preferred identifier for the same BE in the same scope

- **be**: the type of BE

- **organism**: the BE organism

- **source**: the source of the identifier

- **canonical**: canonical gene product (logical)

- **symbol**: canonical symbol of the identifier

- **Gene_entity**: the gene entity input

- **GeneID** (optional): the gene ID input

- **Gene_source** (optional): the gene source input

- **Gene_organism** (optional): the gene organism input
