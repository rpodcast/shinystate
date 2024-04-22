library(shiny)

source("R/utils.R")
source("R/StorageClass.R")

ui <- function(req) {
  fluidPage(
    textInput("txt", "Input text"),
    textInput("storage_id", "Enter storage ID"),
    bookmarkButton(id = "bookmark1"),
    tableOutput("session_table")
  )
}

server <- function(input, output, session) {
  shiny::setBookmarkExclude(c("bookmark1", "storage_id"))

  p <- StorageClass$new(storage_dir = "storage_dir")
  p$greet()

  lastUpdateTime <- NULL

  observeEvent(input$txt, {
    updateTextInput(
      session, 
      "txt",
      label = glue::glue("Input text (Changed {as.character(Sys.time())})")
    )
  })

  observeEvent(input$bookmark1, {
    p$bookmark_init(input$storage_id)
    session$doBookmark()
    p$trigger_session()
  })

  sessions_df <- reactive({
    p$triggers$session
    p$get_sessions()
  })

  output$session_table <- renderTable({
    req(sessions_df())
    sessions_df()
  })
}

shinyApp(ui, server)