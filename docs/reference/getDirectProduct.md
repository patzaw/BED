# Get the direct product of BE identifiers

The product is directly taken as provided by the original database. This
function does not return indirect relationships.

## Usage

``` r
getDirectProduct(
  ids,
  sources = NULL,
  process = c("is_expressed_as", "is_translated_in", "codes_for"),
  canonical = NA
)
```

## Arguments

- ids:

  list of origin identifiers

- sources:

  a character vector corresponding to the possible origin ID sources. If
  NULL (default), all sources are considered

- process:

  the production process among: "is_expressed_as", "is_translated_in",
  "codes_for".

- canonical:

  If TRUE returns only canonical production process. If FALSE returns
  only non-canonical production processes. If NA (default) canonical
  information is taken into account.

## Value

a data.frame with the following columns:

- **origin**: the origin BE identifiers

- **osource**: the origin database

- **product**: the product BE identifiers

- **psource**: the production database

- **canonical**: whether the production process is canonical or not

The process is also returned as an attribute of the data.frame.

## See also

[getDirectOrigin](https://patzaw.github.io/BED/reference/getDirectOrigin.md),
[convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md)

## Examples

``` r
if (FALSE) { # \dontrun{
oriId <- c("10", "100")
res <- getDirectProduct(
   ids=oriId,
   source="EntrezGene",
   process="is_expressed_as",
   canonical=NA
)
attr(res, "process")
} # }
```
