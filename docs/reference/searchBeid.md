# Search a BEID

Search a BEID

## Usage

``` r
searchBeid(
  x,
  maxHits = 75,
  clean_id_search = TRUE,
  clean_name_search = TRUE,
  fuzzy = TRUE
)
```

## Arguments

- x:

  a character value to search

- maxHits:

  maximum number of raw hits to return

- clean_id_search:

  clean x to avoid error during ID search. Default: TRUE. Set it to
  false if you're sure of your lucene query.

- clean_name_search:

  clean x to avoid error during ID search. Default: TRUE. Set it to
  false if you're sure of your lucene query.

- fuzzy:

  if TRUE (default) a fuzzy search is applied on names and symbols.

## Value

NULL if there is not any match or a data.frame with the following
columns:

- **value**: the matching term

- **from**: the type of the matched term (e.g. BESymbol, GeneID...)

- **be**: the matching biological entity (BE)

- **beid**: the BE identifier

- **source**: the BEID reference database

- **preferred**: TRUE if the BEID is considered as a preferred
  identifier

- **symbol**: BEID canonical symbol

- **name**: BEID name

- **entity**: technical BE identifier

- **GeneID**: Corresponding gene identifier

- **Gene_source**: Gene ID database

- **preferred_gene**: TRUE if the GeneID is considered as a preferred
  identifier

- **Gene_symbol**: Gene symbol

- **Gene_name**: Gene name

- **Gene_entity**: technical gene identifier

- **organism**: gene organism (scientific name)

- **score**: score of the fuzzy search

- **included**: is the search term fully included in the value

- **exact**: is the value an exact match of the term
