library(shiny)
library(bslib)
library(shinystate)

# recommended to define a directory for storage or a pins board
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

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
