options(shiny.devmode = TRUE)
options(shiny.autoload.r = FALSE)
library(shiny)
library(bslib)
library(rlang)

source("R/utils.R")
source("R/StorageClass.R")

storage_dir <- "storage_dir"

storage <- StorageClass$new(
  board_sessions = pins::board_folder(storage_dir),
  local_storage_dir = "storage_dir"
)

ui <- function(req) {
  page_sidebar(
    tags$script(src = "redirect.js"),
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
      textInput(
        "sidebar_text",
        "Enter text",
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
}

server <- function(input, output, session) {
  storage$bookmark_init()
  #storage$set_active_project("testproject")

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

  bookmark_mod("bookmark", storage)
}

shinyApp(ui, server)