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
session is restored by obtaining the last record’s URL value in the
session data frame.

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
          actionButton("add", "Add")
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
    vals$sum <- state$values$currentSum
  })

  observeEvent(input$add, {
    vals$sum <- vals$sum + input$n
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
Shinylive](https://shinylive.io/r/app/#code=NobwRAdghgtgpmAXGKAHVA6ASmANGAYwHsIAXOMpMAdzgCMAnRRASwgGdSoAbbgCgDk7ABZsAnpyjkBuAAQM4qIu1kBeWQUHDSpVO0QB6AwyUATAlE4YGAWgCuEFgDc4DdnAym4TmbIHbdfSMFJWsbaksYDCIGAHMBAEoEgB0IbhZGKAYxPhFxFLSMhiycunZ0ugKK4uzc0QgJLnIC1M4YqFi4WQAeG1kAZVJ2zoBhbkt2ABIIOGo+Fog7Fh6+gDMHAlIWEj4FAEc7OE4E2RBU2VlUDrgAfXYWLzosvnOL2S3Sbi71ZLAAIUsLAIsgAguhfrhXhd7o8smpZDD6M8oW8oARiAxTNsIC8IG98bIiKgKPDNL87O4GDc2Kg7KR2BDZL9JORfglIXiCRc0RisSQblcZvwUVyHvDyZTqRBafSISKCb8AKqU2QASWldIZeHl+PIAA9SOqZbiuVzfqQDXLOaa3uM6HBuOKwABRMiuWQAFRYnzgVpt+NQ4wIcGERG4XgYToIwigEE671EWp1b3ZyYu0bgBAA1nQiHqjXSXoQ0Fq5L8RmhvTwWAAvX1gVPW03lB6uAukE3+i6-OhsUtp21Qe2On5gABydhg9sjRFWsl7HD9XdkMDY8IAjBzlyuoHr4QBWAAMW+XTh4h3hAGZDwPG120VsSH86UMcb8oKZTIzfiDP2zk3epo8jEfIQAKsYOp2NpiqOLL1ieNq-H8RBEFmMBZFmAxNPBA4Ptiz46DsPYoWhGHfv8JHoQwWZsghQGbPhL5EWAChtAo5FYEcQwKLIAAylikLIyGoVRNENgB8oFPigEXBStx5A0cHzHRFiYlBbyqaYNzCHAH6uEWYKoLIADydIyrR8qBkQpCmboha-FinAAArcNZ-5NlJsgFAAvqkrSuC4ka9LI6wQAxOw0nSchEGZUUIkc9wkCcZycmx1yTAosQsJwrg3PAXCmFIUDzH5nJntwKjBQoeEuAAaueRy5JO8KHgsFxWaQNwfF8KzyLpDEuHwKX4iwc58AAhApYjMNlHoMHSwg5JFpCTBapBJKc8rlRewW-AAInAqxQHY3CCV6Pq-Ci3myA67ibU2FzbV0wXLatlpNr5EAoqNsh8K9Fh6MlW0Nb1Qx2Og+lPZ5FyfSiCikHYDA4lDrzeW1hIQMJpHUXwoXhTicFA02cGTE9UwEIjChkP0zXBeVUzsJOqPoyQnFsXAuMbI+BPYUT+L05MjMwL1JNk5MFMMFTpA0zAzOlRcRBlAFcDOi4ZB-RqK0fqYcjDW8AtC71BvNQA1LIr1fZyaPy4SsUrY5pAudZvVUxGTsdnrFz7HwHVdd6XzzNDsh7sFR3esI6zcJMETemwsQogulV9O4ex8KuOJ6uyO56nwmdyF8cakMI0R0vCr2J7IZvrkHiYdvKep0RcjC6VmKjqInjcaGGToAMSHoeADsdAEAATEu+K5pi7qjtQoistqD3B3aToAOpQLHcbvCw8DvEQsgzAaN3zag3O-Wu6fsCkC9cuha7qL73Uc0HnnW5bCtKwwLiqxQHbl5RGG6xRGlTogtoB6FDB2IOIgiDUDHNZUaQIpDYiLP0BK2IER2HRAlSO3AxAIigC4L84krYsw-l-NWv9NYZS4jEOAgDiZoP5KYOcwVgFwEmJ0Tq7h2CJQ4CVYm3F0qsW4hzLgLB+DcN4TcZhkxEbcDkHidQ1cX7o3cKQLGolnR6gINwOwXg+BkhQH+PATIwC5hEmRExvxhG0LZD5UqU1DJ8CWHISkgU5AUCHF8DRGE45Ojca4NkYBvIAF0gA)
