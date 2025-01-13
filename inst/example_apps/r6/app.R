library(shiny)
library(bslib)
library(shinystate)
library(R6)
library(ggplot2)

source("modules/varselect.R")
source("modules/scatterplot.R")

storage <- StorageClass$new()
df <- data(ChickWeight)

Variables <- R6::R6Class(
  classname = "Variables",
  public = list(
    triggers = reactiveValues(plot = 0),
    trigger_plot = function() {
      self$triggers$plot <- self$triggers$plot + 1
    },

    varX = NULL,
    varY = NULL,
    set_vars = function(varX, varY) {
      self$varX <- varX
      self$varY <- varY
    }
  )
)

DataManager <- R6::R6Class(
  classname = "DataManager",
  public = list(
    dataset = ChickWeight
  )
)

ui <- function(request) {
  page_fluid(
    use_shinystate(),
    layout_column_wrap(
      width = 1/4,
      varselect_UI("plot1_vars"),
      scatterplot_UI("plot1"),
      varselect_UI("plot2_vars"),
      scatterplot_UI("plot2")
    )
  )
}

server <- function(input, output, session) {
  DataManager <- DataManager$new()
  Variables1 <- Variables$new()
  Variables2 <- Variables$new()

  varselect_server("plot1_vars", Variables1)
  varselect_server("plot2_vars", Variables2)

  scatterplot_Server("plot1", variables = Variables1, data = DataManager)
  scatterplot_Server("plot2", variables = Variables2, data = DataManager)
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
