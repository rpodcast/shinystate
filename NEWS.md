# shinystate (development version)

* Session metadata is now stored in each bookmark pin's metadata field instead of a separate shared "sessions" pin. This eliminates race conditions from concurrent writes. Legacy sessions from v0.1.0 and earlier are automatically migrated on first use.
* Fixed race condition where multiple concurrent bookmark saves could result in metadata loss and orphaned bookmark data
* Added `reactive_sessions()` method to `StorageClass` for reactive bookmark lists that refresh based on triggers
* Added `validate_session_metadata()` to ensure metadata fields are scalar values
* In `examples-shiny`, fixed bookmark module example to properly refresh session list after save/delete operations
* In `examples-shiny`, fixed filter module to handle NULL parameter values during bookmark restoration
* Session timestamp is now automatically added by the system in ISO 8601 format if not provided by the user
* Updated unit tests to cover new functionality and edge cases as well as migration from legacy session storage
* Removed committed storage from inst/examples-shiny/r6

# shinystate 0.1.0

* Initial CRAN release
* Fix typo in test for session ID extraction
* Clean up basic app example and leverage `{bslib}` for user interface
* Streamline example application utilizing R6 classes, along with a new feature to save and restore state of the R6 object. 
* Remove dependency on dplyr by using base R operations to filter and bind rows of session data frames.

# shinystate 0.0.0.9000

* Create initial version of R6 class `StorageClass`
* Add example Shiny applications utilizing the package
