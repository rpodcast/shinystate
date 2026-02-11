# shinystate

## Introduction

`shinystate` is an R package that enables Shiny application developers
to customize key features of [bookmarkable
state](https://shiny.posit.co/r/articles/share/bookmarking-state/). The
bookmarkable state feature included in `shiny` lets an application user
save the state of the application (such as the values of inputs), in
which the state can either be encoded in a custom URL or saved as
objects to a hosting server. For a standard Shiny application with a
small number of input controls, the built-in bookmarkable state features
will likely suffice. However, a handful of limitations exist for
intermediate or complex applications:

- Encoding a large number of input settings using the URL method may
  reach or surpass the allowable length of a URL in web browsers.
- Saving bookmarkable state to a server requires a compatible hosting
  platform (such as Posit Connect or Shiny Server Pro). Even with those
  hosting providers, the bookmarkable state session files are saved to
  directories in the hosting server only accessible by system accounts,
  and not easily shared between users.

Shiny includes the ability to augment bookmarkable state with callback
functions as discussed in the [advanced
bookmarking](https://shiny.posit.co/r/articles/share/advanced-bookmarking/)
article, intended to assist with applications involving a complex
reactive structure alongside user inputs. On the surface, these
callbacks appear to address different issues than the aforementioned
limitations. In the inagural R/Pharma conference held in 2018, Joe Cheng
shared a [Shiny application](https://github.com/jcheng5/rpharma-demo)
demonstrating small enhancements to managing multiple bookmarkable state
sessions for the current user in a development context. The `shinystate`
package incorporates novel approaches to offer Shiny developers an
intuitive framework to address these limitations:

- Integrate with the`pins` package to offer multiple storage locations
  to save bookmarkable state files.
- Add optional metadata to compliment the existing bookmarkable state
  objects as the time a snapshot is created.
- Perform bookmarkable state operations using a new `R6` class called
  `StorageClass`.

## Installation

The [shinystate](https://rpodcast.github.io/shinystate/) package can be
installed from CRAN:

``` r
install.packages("shinystate")
```

## Usage

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

## Example Application

Below is an example application illustrating the default usage of
`shinystate`. The application has a small set of user inputs as well as
a reactive value that will also be saved as part of the bookmarkable
state session. A pair of action buttons trigger the saving and loading
of bookmarkable state within their respective `observeEvent`
expressions. In this application, the most recent bookmarkable state
session is restored by obtaining the most recent record’s URL value in
the session data frame.

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
        open = c("user_inputs", "state"),
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
          ),
          actionButton("add", "Add"),
          tags$p(tags$strong("Current Sum:"), textOutput("sum", inline = TRUE))
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

  vals <- reactiveValues(sum = 0)

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

  onBookmark(function(state) {
    state$values$currentSum <- vals$sum
  })

  onRestore(function(state) {
    if (!is.null(state$values$currentSum)) {
      vals$sum <- state$values$currentSum
    }
  })

  observeEvent(input$add, {
    vals$sum <- vals$sum + 1
  })

  output$sum <- renderText({
    as.character(vals$sum)
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

### Try it out in Shinylive

[Open in
Shinylive](https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgDk7ABZsAnpyjkBuAAQM4qIu1kBeWQUHDSpVO0QB6AwyUATAlE4YGAWgCuEFgDc4DdnAym4TmbIHbdfSMFJWsbaksYDCIGAHMBAEoEgB0IbhZGKAYxPhFxFLSMhiycunZ0ugKK4uzc0QgJLnIC1M4YqFi4WQAeG1kAZVJ2zoBhbkt2ABIIOGo+Fog7Fh6+gDMHAlIWEj4FAEc7OE4E2RBU2VlUDrgAfXYWLzosvnOL2S3Sbi71ZLAAIUsLAIsgAguhfrhXhd7o8smpZDD6M8oW8oARiAxTNsIC8IG98bIiKgKPDNL87O4GDc2Kg7KR2BDZL9JORfglIXiCRc0RisSQblcZvwUVyHvDyZTqRBafSISKCb8AKqU2QASWldIZeHl+PIAA9SOqZbiuVzfqQDXLOaa3uM6HBuOKwABRMiuWQAFRYnzgVpt+NQ4wIcGERG4XgYToIwigEE671EWp1b3ZyYu0bgBAA1nQiHqjXSXoQ0Fq5L8RmhvTwWAAvX1gVPW03lB6uAukE3+i6-OhsUtp21Qe2On5gABydhg9sjRFWsl7HD9XdkMDY8IAjBzlyuoHr4QBWAAMW+XTh4h3hAGZDwPG120VsSH86UMcb8oKZTIzfiDP2yTzaXCxFMqB8EBUycAwJCxEWIx2AwChkAMk6IP+7xwAaADydLGsyk6Mmw6QzPCHpYIqzpJMmd6mjyMR8hAAqxg6nY2mKo4svWAGmr8fxEEQWYwFkWYDE0nEDg+2LPjoOw9nxAlCd+-xyYJDBZv+4mbJJL4yWAChtAoilYEcQwKLIAAylikLIvH8SpakNlR8oFPi1EXBStx5A0HHzFxFiYixbx+aYNzCHAH6uEWYKoLI2G6HS6lNhcgZEKQsW4WAWKcAACtwKVsiizmyAUAC+qStK4LiRr0sjrBAmk7DSdJyEQOFNQiRz3CQJxnJy+nXJMCixCwnCuDc8BcKYUhQPMZWcme3AqNVCgSS4ABq55HLkk7woeCxJblpA3B8XwrPIYWaS4fA9fiLBznwACEnliMww0egwdLCDkjWkJMFqkEkpzyvNF7Vb8AAicCrFAdjcFZXo+r8KLFbIDruIDiWyMDXTVd9v2Wk2pUQCit2yHwuMWHo3VAxtp1DHY6ARVjhUXITKIKKQ8E4kzrzFXthIQDZ8mqXwtX1TiHFU02HGTFjUwEPBiGkP023VfNEH4ZyvOzRcJBGfpcAixsj7i6Jks3Xd93DRgiy8LkokyxtcsKxQSuTgD10EmrkzsCrfTS7LkzywhLvKzASM83zRBlBVcDOi4ZBkxqP0fqYcgexcXs+zAp2Z9tADUsjrhH2uEq1P1Z6diERh6GEdunsiWBg0ZZA+jM8OrMCFVrROci1cU-ZlpA5SllcUBGw912zcB7HwyWHcdBuUU2e7VVD3rCOs3CTBE3psLEKILotfvT3wq44nq7I7nqfAX3IXxxqQwjRHS8K44fsgF+uzOyImHbynqXELiMDClmFQ6hD6AI0GGJ0ABiQ8h4ADsdACAACYlz4lzJid0o5qCiFZNqDGeo7ROgAOpQF3nGd4LB4DvCILIGYBoUbvVQMbUma4z7sBSAQrkgk1zqDnkdb0XwZpNi7pHaODAXBxxdonGUkxcy2SEmnFEfVOje2gHoUMHZv4iCINQMcKVbpAikNiIs-QOrYgRHYdEHVN7cDEAiKALgvwOU1uIykUj44dlxnpEycBlFSwsfyUwc5qqqLgJMToh13DsE6hwER+JwkDWMjEA2XAWD8BiXEm4ITJjwW4HIPE6gv5iJLu4Uggs7LOj1AQbgdgvB8DJCgP8eAmRgAUULeyZZdIpIMg2Eqs0npRT4EsOQHjXByAoEOL4lShJ7ydOMhgbIwDFQALpAA)
