# Find Biological Entity

Find Biological Entity in BED based on their IDs, symbols and names

## Usage

``` r
findBe(
  be = NULL,
  organism = NULL,
  ncharSymb = 4,
  ncharName = 8,
  restricted = TRUE,
  by = 20,
  exclude = c("BEDTech_gene", "BEDTech_transcript")
)
```

## Arguments

- be:

  optional. If provided the search is focused on provided BEs.

- organism:

  optional. If provided the search is focused on provided organisms.

- ncharSymb:

  The minimum number of characters in searched to consider incomplete
  symbol matches.

- ncharName:

  The minimum number of characters in searched to consider incomplete
  name matches.

- restricted:

  boolean indicating if the results should be restricted to current
  version of to BEID db. If FALSE former BEID are also returned:
  **Depending on history it can take a very long time to return** **a
  very large result!**

- by:

  number of found items to be converted into relevant IDs.

- exclude:

  database to exclude from possible selection. Used to filter out
  technical database names such as "BEDTech_gene" and
  "BEDTech_transcript" used to manage orphan IDs (not linked to any gene
  based on information taken from sources)

## Value

A data frame with the following fields:

- **found**: the element found in BED corresponding to the searched term

- **be**: the type of the element

- **source**: the source of the element

- **organism**: the related organism

- **entity**: the related entity internal ID

- **ebe**: the BE of the related entity

- **canonical**: if the symbol is canonical

- **Relevant ID**: the seeked element id

- **Symbol**: the symbol(s) of the corresponding gene(s)

- **Name**: the symbol(s) of the corresponding gene(s)

Scope ("be", "source" and "organism") is provided as a named list in the
"scope" attributes: \`attr(x, "scope")“
