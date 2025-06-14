varselect_UI <- function(id) {
  ns <- NS(id)
  var_choices <- list(
    "var1",
    "var2",
    "var3",
    "var4"
  )

  tagList(
    selectInput(
      ns("xvar"),
      "Select X Variable",
      choices = var_choices,
      selected = "var1"
    ),
    verbatimTextOutput(ns("xvar_print")),
    selectInput(
      ns("yvar"),
      "Select Y Variable",
      choices = var_choices,
      selected = "var2"
    ),
    verbatimTextOutput(ns("yvar_print"))
  )
}

varselect_server <- function(id, variables, count) {
  moduleServer(id, function(input, output, session) {
    output$xvar_print <- renderPrint({
      req(input$xvar)
      print(input$xvar)
    })
    output$yvar_print <- renderPrint({
      req(input$yvar)
      print(input$yvar)
    })
    observeEvent(list(input$xvar, input$yvar), {
      variables$set_vars(varX = input$xvar, varY = input$yvar)
      count$setIncrement()
    })
  })
}