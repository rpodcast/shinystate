# shinystate

[![The project has reached a stable, usable state and is being actively
developed.](https://www.repostatus.org/badges/latest/active.svg)](https://www.repostatus.org/#active)
[![Monthly
Downloads](https://cranlogs.r-pkg.org/badges/shinystate)](https://CRAN.R-project.org/package=shinystate)
[![Total
Downloads](https://cranlogs.r-pkg.org/badges/grand-total/shinystate)](https://CRAN.R-project.org/package=shinystate)

`shinystate` is an R package that provides additional customization on
top of the standard Shiny [bookmarkable
state](https://shiny.posit.co/r/articles/share/bookmarking-state/)
capabilities.

## Installation

``` r
# Install the released version from CRAN
install.packages("shinystate")

# Or the development version from GitHub:
remotes::install_github("rpodcast/shinystate")
```

## Why `shinystate`?

If your Shiny application leverages bookmarkable state and the default
feature set is working for your use case, then `shinystate` is likely
not value-added.

However, as applications grow in complexity and are used in high-stakes
situations, you may wish your application could support the following
features:

- Flexible configuration of where bookmarkable state files are stored,
  whether on the same file system as the server running the application,
  or in a separate repository such as cloud storage.
- Allow users to save multiple bookmarkable state sessions, tailored to
  situations such as multiple “projects” inside the same application.
- Augment the bookmarkable state artifacts with metadata of your
  choosing. Possible metadata could include custom names and timestamps.

The `shinystate` package offers an intuitive class system built upon the
`R6` package with methods tailored to the common operations with
managing bookmarkable state.

## How to use it?

To enable saving bookmarkable state with `shinystate`, you need to:

1.  Load the package:
    [`library(shinystate)`](https://rpodcast.github.io/shinystate/)
2.  Create an instance of the `StorageClass` class outside of the
    application user interface and server functions:
    `StorageClass$new()`
3.  Include
    [`use_shinystate()`](https://rpodcast.github.io/shinystate/reference/use_shinystate.md)
    in your UI definition
4.  Call the `register_metadata()` method from your instance of the
    `StorageClass` class at the beginning of the application server
    function
5.  Enable the save-to-server bookmarking method by adding
    `enableBookmarking = 'server'` in the call to
    [`shinyApp()`](https://rdrr.io/pkg/shiny/man/shinyApp.html)
6.  Call the `snapshot()` method from your instance of the
    `StorageClass` class to save the state of the Shiny app session
7.  Call the `restore()` method from your instance of the `StorageClass`
    class to restore a saved session based on the session URL, available
    in the data frame returned from the `get_sessions()` method.

Below is an example application illustrating the default usage of
`shinystate`. Visit the [Getting
Started](https://rpodcast.github.io/shinystate/articles/shinystate.html)
for additional details.

``` r
library(shiny)
library(bslib)
library(shinystate)

storage <- StorageClass$new()

ui <- function(request) {
  page_sidebar(
    title = "Basic App",
    sidebar = sidebar(
      accordion(
        open = TRUE,
        accordion_panel(
          id = "user_inputs",
          "User Inputs",
          textInput(
            "txt",
            label = "Enter Title",
            placeholder = "change this"
          ),
          checkboxInput("caps", "Capitalize"),
          sliderInput(
            "bins",
            label = "Number of bins",
            min = 1,
            max = 50,
            value = 30
          )
        ),
        accordion_panel(
          id = "state",
          "Bookmark State",
          actionButton("bookmark", "Bookmark"),
          actionButton("restore", "Restore Last Bookmark")
        )
      )
    ),
    use_shinystate(),
    card(
      card_header("App Output"),
      plotOutput("distPlot")
    )
  )
}

server <- function(input, output, session) {
  storage$register_metadata()

  plot_title <- reactive({
    if (!shiny::isTruthy(input$txt)) {
      value <- "Default Title"
    } else {
      value <- input$txt
    }

    if (input$caps) {
      value <- toupper(value)
    }

    return(value)
  })

  output$distPlot <- renderPlot({
    req(plot_title())
    x <- faithful$waiting
    bins <- seq(min(x), max(x), length.out = input$bins + 1)
    hist(
      x,
      breaks = bins,
      col = "#007bc2",
      border = "white",
      xlab = "Waiting time to next eruption (in mins)",
      main = plot_title()
    )
  })

  observeEvent(input$bookmark, {
    storage$snapshot()
    showNotification("Session successfully saved")
  })

  observeEvent(input$restore, {
    session_df <- storage$get_sessions()
    storage$restore(tail(session_df$url, n = 1))
  })

  setBookmarkExclude(c("add", "bookmark", "restore"))
}

shinyApp(ui, server, enableBookmarking = "server")
```

## Code of Conduct

Please note that the shinystate project is released with a [Contributor
Code of
Conduct](https://contributor-covenant.org/version/2/1/CODE_OF_CONDUCT.html).
By contributing to this project, you agree to abide by its terms.
