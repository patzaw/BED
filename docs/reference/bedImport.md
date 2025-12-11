# Feeding BED: Imports a data.frame in the BED graph database

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
bedImport(cql, toImport, periodicCommit = 10000, ...)
```

## Arguments

- cql:

  the CQL query to be applied on each row of toImport

- toImport:

  the data.frame to be imported as "row". Use "row.FIELD" in the cql
  query to refer to one FIELD of the toImport data.frame

- periodicCommit:

  use periodic commit when loading the data (default: 1000).

- ...:

  additional parameters for
  [bedCall](https://patzaw.github.io/BED/reference/bedCall.md)

## Value

the results of the query

## See also

[bedCall](https://patzaw.github.io/BED/reference/bedCall.md),
[neo2R::import_from_df](https://rdrr.io/pkg/neo2R/man/import_from_df.html)
