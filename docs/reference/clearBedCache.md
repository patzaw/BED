# Clear the BED cache SQLite database

Clear the BED cache SQLite database

## Usage

``` r
clearBedCache(queries = NULL, force = FALSE, hard = FALSE, verbose = FALSE)
```

## Arguments

- queries:

  a character vector of the names of queries to remove. If NULL all
  queries are removed.

- force:

  if TRUE clear the BED cache table even if cache file is not found

- hard:

  if TRUE remove everything in cache without checking file names

- verbose:

  display some information during the process

## See also

[lsBedCache](https://patzaw.github.io/BED/reference/lsBedCache.md)
