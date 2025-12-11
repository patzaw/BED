# Identify the biological entity (BE) targeted by probes and construct the CQL sub-query to map probes to the BE

Internal use

## Usage

``` r
genProbePath(platform)
```

## Arguments

- platform:

  the platform of the probes

## Value

A character value corresponding to the sub-query. The `attr(,"be")`
correspond to the BE targeted by probes

## See also

[genBePath](https://patzaw.github.io/BED/reference/genBePath.md),
[listPlatforms](https://patzaw.github.io/BED/reference/listPlatforms.md)
