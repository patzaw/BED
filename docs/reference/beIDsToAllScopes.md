# Find all BEID and ProbeID corresponding to a BE

Find all BEID and ProbeID corresponding to a BE

## Usage

``` r
beIDsToAllScopes(
  beids,
  be,
  source,
  organism,
  entities = NULL,
  canonical_symbols = TRUE
)
```

## Arguments

- beids:

  a character vector of gene identifiers

- be:

  one BE. **Guessed if not provided**

- source:

  the source of gene identifiers. **Guessed if not provided**

- organism:

  the gene organism. **Guessed if not provided**

- entities:

  a numeric vector of gene entity. If NULL (default), beids, source and
  organism arguments are used to identify BEs. Be carefull when using
  entities as these identifiers are not stable.

- canonical_symbols:

  return only canonical symbols (default: TRUE).

## Value

A data.frame with the following fields:

- **value**: the identifier

- **be**: the type of BE

- **source**: the source of the identifier

- **organism**: the BE organism

- **symbol**: canonical symbol of the identifier

- **BE_entity**: the BE entity input

- **BEID** (optional): the BE ID input

- **BE_source** (optional): the BE source input
