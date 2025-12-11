# Get a conversion table between biological entity (BE) identifiers

Get a conversion table between biological entity (BE) identifiers

## Usage

``` r
getBeIdConvTable(
  from,
  to = from,
  from.source,
  to.source,
  organism,
  caseSensitive = FALSE,
  canonical = FALSE,
  restricted = TRUE,
  entity = TRUE,
  verbose = FALSE,
  recache = FALSE,
  filter = NULL,
  limForCache = 100
)
```

## Arguments

- from:

  one BE or "Probe"

- to:

  one BE or "Probe"

- from.source:

  the from BE ID database if BE or the from probe platform if Probe

- to.source:

  the to BE ID database if BE or the to probe platform if Probe

- organism:

  organism name

- caseSensitive:

  if TRUE the case of provided symbols is taken into account during the
  conversion and selection. This option will only affect the conversion
  from "Symbol" (default: caseSensitive=FALSE). All the other conversion
  will be case sensitive.

- canonical:

  if TRUE, only returns the canonical "Symbol". (default: FALSE)

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned:
  **Depending on history it can take a very long time to return a very
  large result!**

- entity:

  boolean indicating if the technical ID of to BE should be returned

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

a data.frame mapping BE IDs with the following fields:

- **from**: the from BE ID

- **to**: the to BE ID

- **entity**: (optional) the technical ID of to BE

- **preferred**: true if "to" is the preferred identifier for the entity

## See also

[getHomTable](https://patzaw.github.io/BED/reference/getHomTable.md),
[listBe](https://patzaw.github.io/BED/reference/listBe.md),
[listPlatforms](https://patzaw.github.io/BED/reference/listPlatforms.md),
[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdConvTable(
    from="Gene", from.source="EntrezGene",
    to.source="Ens_gene",
    organism="human"
)
} # }
```
