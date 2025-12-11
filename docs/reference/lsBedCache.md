# List all the BED queries in cache and the total size of the cache

List all the BED queries in cache and the total size of the cache

## Usage

``` r
lsBedCache(verbose = TRUE)
```

## Arguments

- verbose:

  if TRUE (default) prints a message displaying the total size of the
  cache

## Value

A data.frame giving for each query (row names) its size in Bytes (column
"size") and in human readable format (column "hr"). The attribute
"Total" corresponds to the sum of all the file size.

## See also

[clearBedCache](https://patzaw.github.io/BED/reference/clearBedCache.md)
