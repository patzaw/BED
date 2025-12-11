# Compare 2 BED database instances

Compare 2 BED database instances

## Usage

``` r
compareBedInstances(connections)
```

## Arguments

- connections:

  a numeric vector of length 1 or 2 providing connections from
  [lsBedConnections](https://patzaw.github.io/BED/reference/lsBedConnections.md)
  to be compared.

## Value

If only one connection is provided, the function returns a list with
information about BEID and platforms available for the connection along
with DB version information. If two connections are provided the same
information as above is provided for the 2 connection named V1 and V2 in
that order. In addition, differences observed between the 2 instances
are reported for BEID and platforms.

## Details

The current connection is restored when exiting this function.
