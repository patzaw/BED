# Check if there is a connection to a BED database

Check if there is a connection to a BED database

## Usage

``` r
checkBedConn(verbose = FALSE)
```

## Arguments

- verbose:

  if TRUE print information about the BED connection (default: FALSE).

## Value

- TRUE if the connection can be established

- Or FALSE if the connection cannot be established or the "System" node
  does not exist or does not have "BED" as name or any version recorded.

## See also

[connectToBed](https://patzaw.github.io/BED/reference/connectToBed.md)
