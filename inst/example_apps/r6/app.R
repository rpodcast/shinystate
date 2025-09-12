library(shiny)
library(bslib)
library(shinystate)
library(R6)

# recommended to define a directory for storage or a pins board
storage <- StorageClass$new()

ui <- function(request) {
  page_sidebar(
    title = "Basic App",
    sidebar = sidebar(
      accordion(
        open = TRUE,
        accordion_panel(
          id = "user_inputs",
          "User Inputs",
          numericInput(
            "number",
            label = "Enter Number",
            value = 0,
            min = -9999,
            max = 9999
          ),
          actionButton("add", "Add")
        ),
        accordion_panel(
          id = "state",
          "Bookmark State",
          actionButton("bookmark", "Bookmark"),
          actionButton("restore", "Restore Last Bookmark")
        )
      )
    ),
    use_shinystate(),
    card(
      card_header("App Output"),
      uiOutput("current_sum")
    )
  )
}

server <- function(input, output, session) {
  storage$register_metadata()

  trigger <- reactiveVal(NULL)

  # R6 class to track sum
  Accumulator <- R6Class(
    "Accumulator",
    list(
      sum = 0,
      add = function(x = 1) {
        self$sum <- self$sum + x
        invisible(self)
      },
      serialize = function() {
        # Return a list with class definition and instance data
        list(
          class_name = "Accumulator",
          data = list(sum = self$sum),
          # Store the class definition as text
          class_def = deparse(substitute(Accumulator))
        )
      }
    )
  )

  # Add a static method to recreate from serialized data
  Accumulator$deserialize <- function(serialized_data) {
    instance <- Accumulator$new()
    instance$sum <- serialized_data$data$sum
    instance
  }

  x <- Accumulator$new()

  onBookmark(function(state) {
    message("entered onBookmark block!")
    serialized <- x$serialize()
    saveRDS(serialized, file.path(state$dir, "accumulator_serialized.rds"))
  })

  onRestored(function(state) {
    if (!is.null(state$dir)) {
      # read saved file
      if (file.exists(file.path(state$dir, "accumulator_serialized.rds"))) {
        loaded_data <- readRDS(file.path(
          state$dir,
          "accumulator_serialized.rds"
        ))
        x <<- Accumulator$deserialize(loaded_data)
        trigger(rnorm(1))
      }
    }
  })

  observeEvent(input$add, {
    x$add(input$number)
    trigger(rnorm(1))
  })

  output$current_sum <- renderUI({
    trigger()
    tags$p(paste0("The Current Sum is: ", x$sum))
  })

  observeEvent(input$bookmark, {
    serialized <- x$serialize()
    storage$snapshot()
    showNotification("Session successfully saved")
  })

  observeEvent(input$restore, {
    session_df <- storage$get_sessions()
    storage$restore(tail(session_df$url, n = 1))
  })

  setBookmarkExclude(c("add", "number", "bookmark", "restore"))
}

shinyApp(ui, server, onStart = function() {
  shiny::enableBookmarking("server")
})
