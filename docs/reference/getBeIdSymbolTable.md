# Get a table of biological entity (BE) identifiers and symbols

Get a table of biological entity (BE) identifiers and symbols

## Usage

``` r
getBeIdSymbolTable(
  be,
  source,
  organism,
  restricted,
  entity = TRUE,
  verbose = FALSE,
  recache = FALSE,
  filter = NULL
)
```

## Arguments

- be:

  one BE

- source:

  the BE ID database

- organism:

  organism name

- restricted:

  boolean indicating if the results should be restricted to direct
  symbols

- entity:

  boolean indicating if the technical ID of BE should be returned

- verbose:

  boolean indicating if the CQL query should be displayed

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

- filter:

  character vector on which to filter id. If NULL (default), the result
  is not filtered: all IDs are taken into account.

## Value

a data.frame with the following fields:

- **id**: the from BE ID

- **symbol**: the BE symbol

- **canonical**: true if the symbol is canonical for the direct BE ID

- **direct**: false if the symbol is not directly associated to the BE
  ID

- **preferred**: true if the id is the preferred identifier for the BE

- **entity**: (optional) the technical ID of to BE

## See also

[getBeIdSymbols](https://patzaw.github.io/BED/reference/getBeIdSymbols.md),
[getBeIdNameTable](https://patzaw.github.io/BED/reference/getBeIdNameTable.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdSymbolTable(
   be="Gene",
   source="EntrezGene",
   organism="human"
)
} # }
```
