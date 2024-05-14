# shinystate <img src='man/figures/logo.png' align="right" width="25%" min-width="120px"/>

<!-- badges: start -->
<!-- badges: end -->

`dhinystate` is an R package that provides additional customization on top of the standard Shiny [bookmarkable state](https://shiny.posit.co/r/articles/share/bookmarking-state/) capabilities.

## Installation

You can install the development version from GitHub with the remotes package:

```r
remotes::install_github("EliLillyCo/shinystate)
```

## Why `shinystate`?

If your Shiny application leverages bookmarkable state and the default feature set is working for your use case, then `shinystate` is likely not value-added. 

However, as applications grow in complexity and are used in high-stakes situations, you may wish your application could support the following features:

* Flexible configuration of where bookmarkable state files are stored, whether on the same file system as the server running the application, or in a separate repository such as cloud storage.
* Allow users to save multiple bookmarkable state sessions, tailored to situations such as multiple "projects" inside the same application.
* Augment the bookmarkable state artifacts with metadata of your choosing. Possible metadata could include custom names and timestamps.
 
The `shinystate` package offers an intuitive class system built upon the `R6` package with methods tailored to the common operations with managing bookmarkable state. 

## Basic Usage

Here is the general setup procedure for incorporating `shinystate` in your Shiny application:

* Load the package in your application with `library(shinystate)` or other methods used in frameworks such as `golem` or `rhino`.
* Create a new storage class object in the beginning of your application with `StorageClass$new()`. Optional parameters exist and are discussed in the detailed user guides.
* Inside the user interface function of your application, add `use_shinystate()`.
* Inside the server function of your application, execute the `register_metadata()` method.
* Add a call to `shiny::enableBookmarking("server")` either in the server function or as part of a custom function used for the `onStart` parameter in `shiny::shinyApp()`.  

Once the setup is complete, you can use the following methods with the storage object to perform common operations:

* `snapshot()`: Save the state of the application as a set of bookmarkable state files.
* `restore(url)`: Restore a previously-saved state based on the unique URL of the snapshot

Here is an example Shiny application inspired by the single-file example from the official [introduction to bookmarking state](https://shiny.posit.co/r/articles/share/bookmarking-state/) article that utilizes `shinystate`:

```r
library(shiny)
library(shinystate)

storage <- StorageClass$new()

ui <- function(request) {
  fluidPage(
    use_shinystate(),
    textInput("txt", "Enter text"),
    checkboxInput("caps", "Capitalize"),
    verbatimTextOutput("out"),
    actionButton("bookmark", "Bookmark"),
    actionButton("restore", "Restore Last Bookmark")
  )
}

server <- function(input, output, session) {
  storage$register_metadata()
  output$out <- renderText({
    if (input$caps) {
      toupper(input$txt)
    } else {
      input$txt
    }
  })

  observeEvent(input$bookmark, {
    storage$snapshot()
    showNotification("Session successfully saved")
  })

  observeEvent(input$restore, {
    session_df <- storage$get_sessions()
    storage$restore(tail(session_df$url, n = 1))
  })

  setBookmarkExclude(c("bookmark", "restore"))
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
```
