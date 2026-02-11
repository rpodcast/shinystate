# shinystate (development version)

## Infrastructure

* Remove committed storage from the `inst/examples-shiny/r6` directory.
* Add the `{golem}` package to the Suggests field and Nix development environment. 
* Updated unit tests to cover new functionality and edge cases as well as migration from legacy session storage
* Add John Brothers as package contributor. 

## New Features

* Export the `saveInterfaceLocal` and `loadInterfaceLocal` functions to facilitate the use of `{shinystate}` with applications creeated with the `{golem}` package. The callbacks defined by these two functions must be executed as part of the `onStart` function defined in `shiny::runApp()` in `{golem}` applications.
* Session metadata is now stored in each bookmark pin's metadata field instead of a separate shared "sessions" pin. This eliminates race conditions from concurrent writes. Legacy sessions from v0.1.0 and earlier are automatically migrated on first use.
* Added `reactive_sessions()` method to `StorageClass` for reactive bookmark lists that refresh based on triggers
* Added `validate_session_metadata()` to ensure metadata fields are scalar values
* Session timestamp is now automatically added by the system in ISO 8601 format if not provided by the user

## Bug Fixes

* Fixed race condition where multiple concurrent bookmark saves could result in metadata loss and orphaned bookmark data
* In `examples-shiny`, fixed bookmark module example to properly refresh session list after save/delete operations
* In `examples-shiny`, fixed filter module to handle NULL parameter values during bookmark restoration

# shinystate 0.1.0

* Initial CRAN release
* Fix typo in test for session ID extraction
* Clean up basic app example and leverage `{bslib}` for user interface
* Streamline example application utilizing R6 classes, along with a new feature to save and restore state of the R6 object. 
* Remove dependency on dplyr by using base R operations to filter and bind rows of session data frames.

# shinystate 0.0.0.9000

* Create initial version of R6 class `StorageClass`
* Add example Shiny applications utilizing the package
