# Search identifier, symbol or name information

**DEPRECATED: use
[searchBeid](https://patzaw.github.io/BED/reference/searchBeid.md) and
[geneIDsToAllScopes](https://patzaw.github.io/BED/reference/geneIDsToAllScopes.md)
instead.** This function is meant to be used with
[getRelevantIds](https://patzaw.github.io/BED/reference/getRelevantIds.md)
in order to implement a dictonary of identifiers of interest. First the
searchId function is used to search a term. Then the
[getRelevantIds](https://patzaw.github.io/BED/reference/getRelevantIds.md)
function is used to find the corresponding ID in a context of interest.

## Usage

``` r
searchId(
  searched,
  be = NULL,
  organism = NULL,
  ncharSymb = 4,
  ncharName = 8,
  verbose = FALSE
)
```

## Arguments

- searched:

  the searched term. Identifiers are searched by exact match. Symbols
  and names are also searched for partial match when searched is greater
  than ncharSymb and ncharName respectively.

- be:

  optional. If provided the search is focused on provided BEs.

- organism:

  optional. If provided the search is focused on provided organisms.

- ncharSymb:

  The minimum number of characters in searched to consider incomplete
  symbol matches.

- ncharName:

  The minimum number of characters in searched to consider incomplete
  name matches.

- verbose:

  boolean indicating if the CQL queries should be displayed

## Value

A data frame with the following fields:

- **found**: the element found in BED corresponding to the searched term

- **be**: the type of the element

- **source**: the source of the element

- **organism**: the related organism

- **entity**: the related entity internal ID

- **ebe**: the BE of the related entity

- **canonical**: if the symbol is canonical

- **gene**: list of the related genes BE internal ID

Exact matches are returned first folowed by the shortest elements.

## See also

[getRelevantIds](https://patzaw.github.io/BED/reference/getRelevantIds.md)
