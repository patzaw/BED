# Cached neo4j call

This function calls neo4j DB the first time a query is sent and puts the
result in the cache SQLite database. The next time the same query is
called, it loads the results directly from cache SQLite database.

## Usage

``` r
cacheBedCall(..., tn, recache = FALSE)
```

## Arguments

- ...:

  params for
  [bedCall](https://patzaw.github.io/BED/reference/bedCall.md)

- tn:

  the name of the cached table

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

## Value

The results of the
[bedCall](https://patzaw.github.io/BED/reference/bedCall.md).

## Details

Use only with "row" result returned by DB request.

Internal use.

## See also

[cacheBedResult](https://patzaw.github.io/BED/reference/cacheBedResult.md),
[bedCall](https://patzaw.github.io/BED/reference/bedCall.md)
