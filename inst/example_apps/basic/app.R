library(shiny)

storage <- StorageClass$new()

ui <- function(request) {
  fluidPage(
    use_shinystate(),
    textInput("txt", "Enter text"),
    checkboxInput("caps", "Capitalize"),
    sliderInput("n", "Value to add", min = 0, max = 100, value = 50),
    actionButton("add", "Add"),
    verbatimTextOutput("out"),
    actionButton("bookmark", "Bookmark"),
    actionButton("restore", "Restore Last Bookmark")
  )
}

server <- function(input, output, session) {
  storage$register_metadata()

  vals <- reactiveValues(sum = 0)

  onBookmark(function(state) {
    state$values$currentSum <- vals$sum
  })

  onRestore(function(state) {
    vals$sum <- state$values$currentSum
  })

  observeEvent(input$add, {
    vals$sum <- vals$sum + input$n
  })

  output$out <- renderText({
    if (input$caps) {
      text <- toupper(input$txt)
    } else {
      text <- input$txt
    }
    glue::glue(
      "current text: {text}
       sum of all previous slider values: {vals$sum}"
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