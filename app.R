library(shiny)

source("R/utils.R")
source("R/StorageClass.R")

storage_dir <- "storage_dir"

ui <- function(req) {
  fluidPage(
    textInput("txt", "Input text"),
    #checkboxInput("x", label = "Check me", value = FALSE),
    #textInput("storage_id", "Enter storage ID"),
    actionButton(inputId = "bookmark1", label = "Save"),
    tableOutput("session_table")
  )
}

server <- function(input, output, session) {
  shiny::setBookmarkExclude(c("bookmark1", "storage_id"))

  p <- StorageClass$new(
    board_sessions = pins::board_folder(storage_dir),
    local_storage_dir = "storage_dir"
  )
  
  p$bookmark_init("my_storage")
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