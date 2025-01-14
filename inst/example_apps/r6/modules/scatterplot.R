scatter_plot <- function(dataset, xvar, yvar) {
  p <- ggplot(dataset, aes(x = .data[[xvar]], y = .data[[yvar]])) +
    geom_point() +
    theme(axis.title = element_text(size = rel(1.2)),
          axis.text = element_text(size = rel(1.1)))

  return(p)
}

scatterplot_UI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("plot")),
    verbatimTextOutput(ns("stat"))
  )
}

scatterplot_Server <- function(id, variables, count, data) {
  moduleServer(
    id, 
    function(input, output, session) {
      output$plot <- renderPlot({
        count$getValue()
        scatter_plot(dataset = data$dataset, xvar = variables$varX, yvar = variables$varY)
      })

      output$stat <- renderPrint({
        count$getValue()
        cor(data$dataset[[variables$varX]], data$dataset[[variables$varY]])
      })
  })
}