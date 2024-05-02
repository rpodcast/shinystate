library(shiny)

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
    session_df <- storage$bmi_storage$reader()
    storage$restore(tail(session_df$url, n = 1))
  })

  setBookmarkExclude(c("bookmark", "restore"))
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})