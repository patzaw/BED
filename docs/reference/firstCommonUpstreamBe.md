# First common upstream BE

Returns the first common Biological Entity (BE) upstream a set of BE.

## Usage

``` r
firstCommonUpstreamBe(beList = listBe(), uniqueOrg = TRUE)
```

## Arguments

- beList:

  a character vector containing BE

- uniqueOrg:

  a logical value indicating if as single organism is under focus. If
  false "Gene" is returned.

## Details

This function is used to identified the level at which different BE
should be compared. Peptides and transcripts should be compared at the
level of transcripts whereas transcripts and objects should be compared
at the level of genes. BE from different organism should be compared at
the level of genes using homologs.

## See also

[listBe](https://patzaw.github.io/BED/reference/listBe.md)

## Examples

``` r
if (FALSE) { # \dontrun{
firstCommonUpstreamBe(c("Object", "Transcript"))
firstCommonUpstreamBe(c("Peptide", "Transcript"))
firstCommonUpstreamBe(c("Peptide", "Transcript"), uniqueOrg=FALSE)
} # }
```
