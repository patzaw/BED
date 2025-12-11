# Identify and remove dubious cross-references

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
cleanDubiousXRef(d, strict = TRUE)
```

## Arguments

- d:

  a cross-reference data.frame with 2 columns.

- strict:

  if TRUE (default), the function returns only unambiguous mappings

## Value

This function returns d without dubious cross-references. Issues are
reported in attr(d, "issues").
