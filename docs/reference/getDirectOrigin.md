# Get the direct origin of BE identifiers

The origin is directly taken as provided by the original database. This
function does not return indirect relationships.

## Usage

``` r
getDirectOrigin(
  ids,
  sources = NULL,
  process = c("is_expressed_as", "is_translated_in", "codes_for")
)
```

## Arguments

- ids:

  list of product identifiers

- sources:

  a character vector corresponding to the possible product ID sources.
  If NULL (default), all sources are considered

- process:

  the production process among: "is_expressed_as", "is_translated_in",
  "codes_for".

## Value

a data.frame with the following columns:

- **origin**: the origin BE identifiers

- **osource**: the origin database

- **product**: the product BE identifiers

- **psource**: the production database

- **canonical**: whether the production process is canonical or not

The process is also returned as an attribute of the data.frame.

## See also

getDirectOrigin,
[convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md)

## Examples

``` r
if (FALSE) { # \dontrun{
oriId <- c("XP_016868427", "NP_001308979")
res <- getDirectOrigin(
   ids=oriId,
   source="RefSeq_peptide",
   process="is_translated_in"
)
attr(res, "process")
} # }
```
