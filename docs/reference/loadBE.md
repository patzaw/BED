# Feeding BED: Load biological entities in BED

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadBE(
  d,
  be = "Gene",
  dbname,
  version = NA,
  deprecated = NA,
  taxId = NA,
  onlyId = FALSE
)
```

## Arguments

- d:

  a data.frame with information about the entities to be loaded. It
  should contain the following fields: "id". If there is a boolean
  column named "preferred", the value is loaded.

- be:

  a character corresponding to the BE type (default: "Gene")

- dbname:

  the DB from which the BE ID are taken

- version:

  the version of the DB from which the BE IDs are taken

- deprecated:

  NA (default) or the date when the ID was deprecated

- taxId:

  the taxonomy ID of the BE organism

- onlyId:

  a logical. If TRUE, only an BEID is created and not the corresponding
  BE.
