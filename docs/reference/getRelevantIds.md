# Get relevant IDs for a formerly identified BE in a context of interest

**DEPRECATED: use
[searchBeid](https://patzaw.github.io/BED/reference/searchBeid.md) and
[geneIDsToAllScopes](https://patzaw.github.io/BED/reference/geneIDsToAllScopes.md)
instead.** This function is meant to be used with
[searchId](https://patzaw.github.io/BED/reference/searchId.md) in order
to implement a dictonary of identifiers of interest. First the
[searchId](https://patzaw.github.io/BED/reference/searchId.md) function
is used to search a term. Then the getRelevantIds function is used to
find the corresponding IDs in a context of interest.

## Usage

``` r
getRelevantIds(
  d,
  selected = 1,
  be = c(listBe(), "Probe"),
  source,
  organism,
  restricted = TRUE,
  simplify = TRUE,
  verbose = FALSE
)
```

## Arguments

- d:

  the data.frame returned by
  [searchId](https://patzaw.github.io/BED/reference/searchId.md).

- selected:

  the rows of interest in d

- be:

  the BE in the context of interest

- source:

  the source of the identifier in the context of interest

- organism:

  the organism in the context of interest

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned:
  **Depending on history it can take a very long time to return** **a
  very large result!**

- simplify:

  if TRUE (default) duplicated IDs are removed from the output

- verbose:

  if TRUE, the CQL query is shown

## Value

The d data.frame with a new column providing the relevant ID in the
context of interest and without the gene field. Scope ("be", "source"
and "organism") is provided as a named list in the "scope" attributes:
`attr(x, "scope")`

## See also

[searchId](https://patzaw.github.io/BED/reference/searchId.md)
