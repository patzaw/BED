# Feeding BED: Register a database of biological entities in BED DB

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
registerBEDB(name, description = NA, currentVersion = NA, idURL = NA)
```

## Arguments

- name:

  of the database (e.g. "Ens_gene")

- description:

  a short description of the database (e.g. "Ensembl gene")

- currentVersion:

  the version taken into account in BED (e.g. 83)

- idURL:

  the URL template to use to retrieve id information. A '%s'
  corresponding to the ID should be present in this character vector of
  length one.
