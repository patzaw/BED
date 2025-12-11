# Feeding BED: Dump and preprocess flat data files from Uniprot

Not exported to avoid unintended modifications of the DB.

## Usage

``` r
dumpUniprotDb(
  taxOfInt,
  divOfInt,
  release,
  ddir,
  ftp = "ftp://ftp.expasy.org/databases/uniprot",
  env = parent.frame(n = 1)
)
```

## Arguments

- taxOfInt:

  the organism of interest (e.g., "9606" for human, "10090" for mouse or
  "10116" for rat)

- divOfInt:

  the taxonomic division to which the organism belong (e.g., "human",
  "rodents", "mammals", "vertebrates")

- release:

  the release of interest (check if already downloaded)

- ddir:

  path to the directory where the data should be saved

- ftp:

  location of the ftp site

- env:

  the R environment in which to load the tables when built
