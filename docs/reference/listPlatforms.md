# Lists all the probe platforms available in the BED database

Lists all the probe platforms available in the BED database

## Usage

``` r
listPlatforms(be = c(NA, listBe()))
```

## Arguments

- be:

  a character vector of BE on which to focus. if NA (default) all the BE
  are considered.

## Value

A data.frame mapping platforms to BE with the following fields:

- **name**: the platform nam

- **description**: platform description

- **focus**: Targeted BE

## See also

[listBe](https://patzaw.github.io/BED/reference/listBe.md),
[listBeIdSources](https://patzaw.github.io/BED/reference/listBeIdSources.md),
[listOrganisms](https://patzaw.github.io/BED/reference/listOrganisms.md),
[getTargetedBe](https://patzaw.github.io/BED/reference/getTargetedBe.md)

## Examples

``` r
if (FALSE) { # \dontrun{
listPlatforms(be="Gene")
listPlatforms()
} # }
```
