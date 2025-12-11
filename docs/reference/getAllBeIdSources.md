# List all the source databases of BE identifiers whatever the BE type

List all the source databases of BE identifiers whatever the BE type

## Usage

``` r
getAllBeIdSources(recache = FALSE)
```

## Arguments

- recache:

  boolean indicating if the CQL query should be run even if the table is
  already in cache

## Value

A data.frame indicating the BE related to the ID source (database).

## See also

[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md),
[listPlatforms](https://patzaw.github.io/BED/reference/listPlatforms.md)
