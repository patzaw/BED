# Convert a BEIDList object in a specific identifier (BEID) scope

Convert a BEIDList object in a specific identifier (BEID) scope

## Usage

``` r
# S3 method for class 'BEIDList'
focusOnScope(
  x,
  be = NULL,
  source = NULL,
  organism = NULL,
  scope = NULL,
  force = FALSE,
  restricted = TRUE,
  prefFilter = TRUE,
  ...
)
```

## Arguments

- x:

  the BEIDList to be converted

- be:

  the type of biological entity to focus on. If NULL (default), it's
  taken from `scope(x)`. Used if `is.null(scope)`

- source:

  the source of BEID to focus on. If NULL (default), it's taken from
  `scope(x)`. Used if `is.null(scope)`

- organism:

  the organism of BEID to focus on. If NULL (default), it's taken from
  `scope(x)`. Used if `is.null(scope)`

- scope:

  a list with the following element:

  - **be**

  - **source**

  - **organism**

- force:

  if TRUE the conversion is done even between identical scopes (default:
  FALSE)

- restricted:

  if TRUE (default) the BEID are limited to current version of the
  source

- prefFilter:

  if TRUE (default) the BEID are limited to prefered identifiers when
  they exist

- ...:

  additional parameters to the BEID conversion function

## Value

A BEIDList
