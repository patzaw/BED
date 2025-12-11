# Call a function on the BED graph

Call a function on the BED graph

## Usage

``` r
bedCall(f, ..., bedCheck = FALSE)
```

## Arguments

- f:

  the function to call

- ...:

  params for f

- bedCheck:

  check if a connection to BED exists (default: FALSE).

## Value

The output of the called function.

## See also

[checkBedConn](https://patzaw.github.io/BED/reference/checkBedConn.md)

## Examples

``` r
if (FALSE) { # \dontrun{
result <- bedCall(
   cypher,
   query=prepCql(
      'MATCH (n:BEID)',
      'WHERE n.value IN $values',
      'RETURN n.value AS value, n.labels, n.database'
   ),
   parameters=list(values=c("10", "100"))
)
} # }
```
