# Add BE ID conversion to a data frame

Add BE ID conversion to a data frame

## Usage

``` r
convDfBeIds(df, idCol = NULL, entity = FALSE, ...)
```

## Arguments

- df:

  the data.frame to be converted

- idCol:

  the column in which ID to convert are. If NULL (default) the row names
  are taken.

- entity:

  if TRUE returns BE instead of BEID (default: FALSE). BE CAREFUL, THIS
  INTERNAL ID IS NOT STABLE AND CANNOT BE USED AS A REFERENCE. This
  internal identifier is useful to avoid biases related to identifier
  redundancy. See
  [../doc/BED.html#3_managing_identifiers](https://patzaw.github.io/BED/doc/BED.html#3_managing_identifiers)

- ...:

  params for the
  [convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md)
  function

## Value

A data.frame with converted IDs. Scope ("be", "source", "organism" and
"entity" (see Arguments)) is provided as a named list in the "scope"
attributes: `attr(x, "scope")`.

## See also

[convBeIds](https://patzaw.github.io/BED/reference/convBeIds.md),
[convBeIdLists](https://patzaw.github.io/BED/reference/convBeIdLists.md)

## Examples

``` r
if (FALSE) { # \dontrun{
toConv <- data.frame(a=1:2, b=3:4)
rownames(toConv) <- c("10", "100")
convDfBeIds(
   df=toConv,
   from="Gene",
   from.source="EntrezGene",
   from.org="human",
   to.source="Ens_gene"
)
} # }
```
