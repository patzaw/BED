# Focus a BE related object on a specific identifier (BEID) scope

Focus a BE related object on a specific identifier (BEID) scope

## Usage

``` r
focusOnScope(
  x,
  be,
  source,
  organism,
  scope,
  force,
  restricted,
  prefFilter,
  ...
)
```

## Arguments

- x:

  an object representing a collection of BEID (e.g. BEIDList)

- be:

  the type of biological entity to focus on. Used if `is.null(scope)`

- source:

  the source of BEID to focus on. Used if `is.null(scope)`

- organism:

  the organism of BEID to focus on. Used if `is.null(scope)`

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

  method specific parameters for BEID conversion

## Value

Depends on the class of x
