library(shiny)
library(bslib)
library(shinystate)
library(R6)
library(ggplot2)

source("modules/varselect.R")
source("modules/scatterplot.R")

storage <- StorageClass$new()

reactiveTrigger <- function() {
  counter <- reactiveVal(0)
  list(
    depend = function() {
      counter()
      invisible()
    },
    trigger = function() {
      counter( isolate(counter()) + 1 )
    }
  )
}

ui <- function(request) {
  page_fluid(
    use_shinystate(),
    layout_column_wrap(
      width = 1/4,
      varselect_UI("plot1_vars"),
      scatterplot_UI("plot1"),
      varselect_UI("plot2_vars"),
      scatterplot_UI("plot2")
    ),
    layout_column_wrap(
      width = 1/2,
      verbatimTextOutput("count1_print"),
      verbatimTextOutput("count2_print")
    ),
    actionButton("bookmark", "Bookmark"),
    actionButton("restore", "Restore Last Bookmark")
  )
}

server <- function(input, output, session) {
  # https://gist.github.com/bborgesr/3350051727550cfa798cb4c9677adcd4
  counter <- R6::R6Class(
    public = list(
      initialize = function(reactive = FALSE) {
        private$reactive = reactive
        private$value = 0
        private$rxTrigger = reactiveTrigger()
      },
      setIncrement = function() {
        if (private$reactive) private$rxTrigger$trigger()
        private$value = private$value + 1
      },
      setDecrement = function() {
        if (private$reactive) private$rxTrigger$trigger()
        private$value = private$value -1
      },
      getValue = function() {
        if (private$reactive) private$rxTrigger$depend()
        return(private$value)
      }
    ),
    private = list(
      reactive = NULL,
      value = NULL,
      rxTrigger = NULL
    )
  )
  
  Variables <- R6::R6Class(
    classname = "Variables",
    public = list( 
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
      dataset = data.frame(
        var1 = rnorm(50),
        var2 = rnorm(50),
        var3 = rnorm(50),
        var4 = rnorm(50)
      )
    )
  )

  DataManager <- DataManager$new()
  Variables1 <- Variables$new()
  Variables2 <- Variables$new()
  count1 <- counter$new(reactive = TRUE)
  count2 <- counter$new(reactive = TRUE)

  varselect_server("plot1_vars", Variables1, count1)
  varselect_server("plot2_vars", Variables2, count2)

  scatterplot_Server("plot1", variables = Variables1, count = count1, data = DataManager)
  scatterplot_Server("plot2", variables = Variables2, count = count2, data = DataManager)

  output$count1_print <- renderPrint({
    print(count1$getValue())
  })

  output$count2_print <- renderPrint({
    print(count2$getValue())
  })
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
