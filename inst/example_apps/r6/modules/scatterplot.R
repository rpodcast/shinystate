scatter_plot <- function(dataset, xvar, yvar) {
  x <- rlang::sym(xvar)
  y <- rlang::sym(yvar)

  p <- ggplot(dataset, aes(x = !!x, y = !!y)) +
    geom_point() +
    theme(axis.title = element_text(size = rel(1.2)),
          axis.text = element_text(size = rel(1.1)))

  return(p)
}

scatterplot_UI <- function(id) {
  ns <- NS(id)
  tagList(
    plotOutput(ns("plot"))
  )
}

scatterplot_Server <- function(id, variables, data) {
  moduleServer(id, function(input, output, session) {
    output$plot <- renderPlot({
      variables$trigger$plot
      scatter_plot(data$dataset, xvar = variables$varX, yvar = variables$varY)
    })
  })
}