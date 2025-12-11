# Guess biological entity (BE), database source and organism of a vector of identifiers.

Guess biological entity (BE), database source and organism of a vector
of identifiers.

## Usage

``` r
guessIdScope(ids, be, source, organism, tcLim = 100)

guessIdOrigin(...)
```

## Arguments

- ids:

  a character vector of identifiers

- be:

  one BE or "Probe". **Guessed if not provided**

- source:

  the BE ID database or "Symbol" if BE or the probe platform if Probe.
  **Guessed if not provided**

- organism:

  organism name. **Guessed if not provided**

- tcLim:

  number of identifiers to check to guess origin for the whole set. Inf
  ==\> no limit.

- ...:

  params for `guessIdScope`

## Value

A list (NULL if no match):

- **be**: a character vector of length 1 providing the best BE guess (NA
  if inconsistent with user input: be, source or organism)

- **source**: a character vector of length 1 providing the best source
  guess (NA if inconsistent with user input: be, source or organism)

- \**organism*\$: a character vector of length 1 providing the best
  organism guess (NA if inconsistent with user input: be, source or
  organism)

The "details" attribute (\`attr(x, "details")“) is a data frame
providing numbers supporting the guess

## Functions

- `guessIdOrigin()`: Deprecated version of guessIdScope

## Examples

``` r
if (FALSE) { # \dontrun{
guessIdScope(ids=c("10", "100"))
} # }
```
