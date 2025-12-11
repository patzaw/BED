# Feeding BED: Download Uniprot information in BED

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
getUniprot(organism, taxDiv, release, ddir)
```

## Arguments

- organism:

  character vector of 1 element corresponding to the organism of
  interest (e.g. "Homo sapiens")

- taxDiv:

  the taxonomic division to which the organism belong (e.g., "human",
  "rodents", "mammals", "vertebrates")

- release:

  the release of interest (check if already downloaded)

- ddir:

  path to the directory where the data should be saved
