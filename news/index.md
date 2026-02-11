# Changelog

## shinystate (development version)

### Infrastructure

- Remove committed storage from the `inst/examples-shiny/r6` directory.
- Add the [golem](https://thinkr-open.github.io/golem/) package to the
  Suggests field and Nix development environment.

### New Features

- Export the `saveInterfaceLocal` and `loadInterfaceLocal` functions to
  facilitate the use of
  [shinystate](https://rpodcast.github.io/shinystate/) with applications
  creeated with the [golem](https://thinkr-open.github.io/golem/)
  package. The callbacks defined by these two functions must be executed
  as part of the `onStart` function defined in
  [`shiny::runApp()`](https://rdrr.io/pkg/shiny/man/runApp.html) in
  [golem](https://thinkr-open.github.io/golem/) applications.

## shinystate 0.1.0

CRAN release: 2025-09-18

- Initial CRAN release
- Fix typo in test for session ID extraction
- Clean up basic app example and leverage
  [bslib](https://rstudio.github.io/bslib/) for user interface
- Streamline example application utilizing R6 classes, along with a new
  feature to save and restore state of the R6 object.
- Remove dependency on dplyr by using base R operations to filter and
  bind rows of session data frames.

## shinystate 0.0.0.9000

- Create initial version of R6 class `StorageClass`
- Add example Shiny applications utilizing the package
