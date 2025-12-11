# Feeding BED: Load attributes for biological entities in BED

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
loadBeAttribute(d, be = "Gene", dbname, attribute)
```

## Arguments

- d:

  a data.frame providing for each BE ID ("id" column) an attribute value
  ("value" column). There can be several values for each id.

- be:

  a character corresponding to the BE type (default: "Gene")

- dbname:

  the DB from which the BE ID are taken

- attribute:

  the name of the attribute to be loaded
