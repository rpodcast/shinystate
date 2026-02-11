# Add shinystate dependency

Include shinystate dependencies in your Shiny application UI

## Usage

``` r
use_shinystate()
```

## Examples

``` r
## Only run examples in interactive R sessions
if (interactive()) {

library(shiny)
library(shinystate)

storage <- StorageClass$new()

ui <- function(request) {
  fluidPage(
    use_shinystate(),
    actionButton("bookmark", "Bookmark"),
    actionButton("restore", "Restore Last Bookmark")
  )
}
}
```
