# Get gene homologs between 2 organisms

Get gene homologs between 2 organisms

## Usage

``` r
getHomTable(
  from.org,
  to.org,
  from.source = "Ens_gene",
  to.source = from.source,
  restricted = TRUE,
  verbose = FALSE,
  recache = FALSE,
  filter = NULL,
  limForCache = 100
)
```

## Arguments

- from.org:

  organism name

- to.org:

  organism name

- from.source:

  the from gene ID database

- to.source:

  the to gene ID database

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned:
  **Depending on history it can take a very long time to return a very**
  **large result!**

- verbose:

  boolean indicating if the CQL query should be displayed

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

- filter:

  character vector on which to filter from IDs. If NULL (default), the
  result is not filtered: all from IDs are taken into account.

- limForCache:

  if there are more filter than limForCache results are collected for
  all IDs (beyond provided ids) and cached for futur queries. If not,
  results are collected only for provided ids and not cached.

## Value

a data.frame mapping gene IDs with the following fields:

- **from**: the from gene ID

- **to**: the to gene ID

## See also

[getBeIdConvTable](https://patzaw.github.io/BED/reference/getBeIdConvTable.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getHomTable(
   from.org="human",
   to.org="mouse"
)
} # }
```
