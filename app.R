library(shiny)

source("R/utils.R")
source("R/StorageClass.R")

ui <- function(req) {
  fluidPage(
    textInput("txt", "Input text"),
    bookmarkButton(id = "bookmark1")
  )
}

server <- function(input, output, session) {
  shiny::setBookmarkExclude(c("bookmark1"))

  p <- StorageClass$new("test123")
  p$bookmark_init()
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
  })

  #shiny::enableBookmarking("server")
}

shinyApp(ui, server)