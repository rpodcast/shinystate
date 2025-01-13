varselect_UI <- function(id) {
  ns <- NS(id)
  var_choices <- list(
    `Weight` = "weight",
    `Time` = "Time",
    `Chick` = "Chick",
    `Diet` = "Diet"
  )

  tagList(
    selectInput(
      ns("xvar"),
      "Select X Variable",
      choices = var_choices,
      selected = "weight"
    ),
    verbatimTextOutput(ns("xvar_print")),
    selectInput(
      ns("yvar"),
      "Select Y Variable",
      choices = var_choices,
      selected = "Time"
    ),
    verbatimTextOutput(ns("yvar_print"))
  )
}

varselect_server <- function(id, variables) {
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
      variables$set_vars(input$xvar, input$yvar)
      variables$trigger_plot()
    })
  })
}