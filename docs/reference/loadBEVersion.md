# Feeding BED: Load biological entities in BED with information about DB version

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadBEVersion(d, be = "Gene", dbname, taxId = NA, onlyId = FALSE)
```

## Arguments

- d:

  a data.frame with information about the entities to be loaded. It
  should contain the following fields: "id", "version" and "deprecated".

- be:

  a character corresponding to the BE type (default: "Gene")

- dbname:

  the DB from which the BE ID are taken

- taxId:

  the taxonomy ID of the BE organism

- onlyId:

  a logical. If TRUE, only an BEID is created and not the corresponding
  BE.
