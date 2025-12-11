# Get a table of biological entity (BE) identifiers and names

Get a table of biological entity (BE) identifiers and names

## Usage

``` r
getBeIdNameTable(
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

  boolean indicating if the results should be restricted to direct names

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

- **name**: the BE name

- **direct**: false if the symbol is not directly associated to the BE
  ID

- **preferred**: true if the id is the preferred identifier for the BE

- **entity**: (optional) the technical ID of to BE

## See also

[getBeIdNames](https://patzaw.github.io/BED/reference/getBeIdNames.md),
[getBeIdSymbolTable](https://patzaw.github.io/BED/reference/getBeIdSymbolTable.md)

## Examples

``` r
if (FALSE) { # \dontrun{
getBeIdNameTable(
   be="Gene",
   source="EntrezGene",
   organism="human"
)
} # }
```
