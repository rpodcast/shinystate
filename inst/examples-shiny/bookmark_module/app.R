library(shiny)
library(shinystate)
library(dplyr)
library(DT)

source("helpers/utils.R")
source("modules/select_module.R")
source("modules/filter_module.R")
source("modules/bookmark_module.R")
source("modules/summarize_module.R")

#  recommended to define a directory for storage or a pins board
storage <- StorageClass$new()

ui <- function(req) {
  tagList(
    # Bootstrap header
    tags$header(
      class = "navbar navbar-default navbar-static-top",
      tags$div(
        class = "container-fluid",
        tags$div(
          class = "navbar-header",
          tags$div(class = "navbar-brand", "R/Pharma demo")
        ),
        # Links for restoring/loading sessions
        tags$ul(
          class = "nav navbar-nav navbar-right",
          tags$li(
            bookmark_modal_load_ui("bookmark")
          ),
          tags$li(
            bookmark_modal_save_ui("bookmark")
          )
        )
      )
    ),
    fluidPage(
      use_shinystate(),
      sidebarLayout(
        position = "right",
        column(
          width = 4,
          wellPanel(
            select_vars_ui("select")
          ),
          wellPanel(
            filter_ui("filter")
          )
        ),
        mainPanel(
          tabsetPanel(
            id = "tabs",
            tabPanel("Plot", tags$br(), plotOutput("plot", height = 600)),
            tabPanel("Summary", tags$br(), verbatimTextOutput("summary")),
            tabPanel("Table", tags$br(), tableOutput("table"))
          )
        )
      )
    )
  )
}

server <- function(input, output, session) {
  callModule(bookmark_mod, "bookmark", storage)
  storage$register_metadata()
  datasetExpr <- reactive(expr(mtcars %>% mutate(cyl = factor(cyl))))
  filterExpr <- callModule(filter_mod, "filter", datasetExpr)
  selectExpr <- callModule(
    select_vars,
    "select",
    reactive(names(eval_clean(datasetExpr()))),
    filterExpr
  )

  data <- reactive({
    resultExpr <- selectExpr()
    df <- eval_clean(resultExpr)
    validate(need(nrow(df) > 0, "No data matches the filter"))
    df
  })

  output$table <- renderTable(
    {
      data()
    },
    rownames = TRUE
  )

  do_plot <- function() {
    plot(data())
  }

  output$plot <- renderPlot({
    do_plot()
  })

  output$summary <- renderPrint({
    summary(data())
  })

  output$code <- renderText({
    format_tidy_code(selectExpr())
  })
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
