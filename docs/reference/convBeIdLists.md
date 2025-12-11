# Converts lists of BE IDs

Converts lists of BE IDs

## Usage

``` r
convBeIdLists(idList, entity = FALSE, ...)
```

## Arguments

- idList:

  a list of IDs lists

- entity:

  if TRUE returns BE instead of BEID (default: FALSE). BE CAREFUL, THIS
  INTERNAL ID IS NOT STABLE AND CANNOT BE USED AS A REFERENCE. This
  internal identifier is useful to avoid biases related to identifier
  redundancy. See \<../doc/BED.html#3_managing_identifiers\>

- ...:

  params for the
  [convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md)
  function

## Value

A list of
[convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md) ouput
ids. Scope ("be", "source" "organism" and "entity" (see Arguments)) is
provided as a named list in the "scope" attributes: `attr(x, "scope")`

## See also

[convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md),
[convDfBeIds](https://patzaw.github.io/BED/reference/convDfBeIds.md)

## Examples

``` r
if (FALSE) { # \dontrun{
convBeIdLists(
   idList=list(a=c("10", "100"), b=c("1000")),
   from="Gene",
   from.source="EntrezGene",
   from.org="human",
   to.source="Ens_gene"
)
} # }
```
