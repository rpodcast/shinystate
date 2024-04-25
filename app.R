options(shiny.devmode = TRUE)
library(shiny)
library(bslib)
library(rlang)

source("R/utils.R")
source("R/StorageClass.R")

storage_dir <- "storage_dir"
bookmark_file_dir <- "bookmark_file_dir"

ui <- page_sidebar(
  title = "Sessions Demo",
  theme = bs_theme(
    base_font = font_google("Roboto", local = FALSE)
  ),
  sidebar = sidebar(
    title = NULL,
    selectInput(
      "vars",
      "Variables to display",
      choices = c("area", "peri", "shape", "perm"),
      selected = NULL,
      multiple = TRUE,
      selectize = TRUE
    ),
    bookmark_modal_save_ui("bookmark"),
    bookmark_modal_load_ui("bookmark")
  ),
  navset_card_underline(
    id = "tabs",
    nav_panel(
      title = "Plot",
      value = "plot",
      plotOutput("plot")
    ),
    nav_panel(
      title = "Summary",
      value = "summary",
      verbatimTextOutput("summary")
    ),
    nav_panel(
      title = "Table",
      value = "table",
      tableOutput("table")
    )
  )
)

server <- function(input, output, session) {
  shiny::setBookmarkExclude(c("bookmark1", "restore", "storage_id"))
  p <- StorageClass$new(
    board_sessions = pins::board_folder(storage_dir),
    local_storage_dir = "bookmark_file_dir"
  )
  p$bookmark_init("my_storage")
  p$greet()

  data <- reactive({
    if (length(input$vars) == 0) {
      return(rock)
    } else {
      rock[, input$vars]
    }
  })

  output$plot <- renderPlot({
    req(data())
    plot(data())
  })

  output$summary <- renderPrint({
    req(data())
    summary(data())
  })

  output$table <- renderTable({
    req(data())
    data()
  }, rownames = TRUE)

  bookmark_mod("bookmark")

  # observeEvent(input$bookmark1, {
  #   p$snapshot()
  # })

  # sessions_df <- reactive({
  #   p$get_sessions()
  # })

  # output$session_table <- renderTable({
  #   req(sessions_df())
  #   sessions_df()
  # })
}

shinyApp(ui, server)