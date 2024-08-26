hello_app <- shinyApp(
  ui = function(request) {
    fluidPage(
      use_shinystate(),
      textInput("txt", "Enter text"),
      checkboxInput("caps", "Capitalize"),
      sliderInput("n", "Value to add", min = 0, max = 100, value = 50),
      actionButton("add", "Add"),
      verbatimTextOutput("out"),
      actionButton("bookmark", "Bookmark"),
      actionButton("restore", "Restore Last Bookmark")
    )
  },
  server = function(input, output, session) {
    storage <- StorageClass$new()
    storage$register_metadata()

    vals <- reactiveValues(sum = 0)
    storage_rv <- reactiveVal(storage$local_storage_dir)
    board_rv <- reactiveVal(storage$board_sessions)

    onBookmark(function(state) {
      state$values$currentSum <- vals$sum
    })

    onRestore(function(state) {
      vals$sum <- state$values$currentSum
    })

    observeEvent(input$add, {
      vals$sum <- vals$sum + input$n
    })

    output$out <- renderText({
      if (input$caps) {
        text <- toupper(input$txt)
      } else {
        text <- input$txt
      }
      glue::glue(
        "current text: {text}
        sum of all previous slider values: {vals$sum}"
      )
    })

    observeEvent(input$bookmark, {
      storage$snapshot()
      showNotification("Session successfully saved")
    })

    observeEvent(input$restore, {
      session_df <- storage$get_sessions()
      storage$restore(tail(session_df$url, n = 1))
    })

    setBookmarkExclude(c("add", "bookmark", "restore"))

    exportTestValues(
      storage_rv = { storage_rv() },
      sum = vals$sum,
      board_rv = { board_rv() }
    )
  }
)

test_that("Bookmark saving works end-to-end", {
  library(shiny)
  withr::with_libpaths("../../prototyping/tmp_lib", {
    app <- AppDriver$new(
      hello_app,
      name = "shinystate-test-app",
      expect_values_screenshot_args = FALSE
    )

    
    # obtain local bookmark storage path
    app_storage_dir <- app$get_value(export = "storage_rv")
    expect_true(fs::is_dir(app_storage_dir))

    # enter sample text
    app$set_inputs(txt = "shinystate")
    app$wait_for_idle(500)
    app$set_inputs(caps = TRUE)
    app$wait_for_idle(500)

    # enter new slider value
    app$set_inputs(n = 75)
    app$wait_for_idle(500)
    app$click("add")
    app$wait_for_idle(500)

    # obtain current values for comparison
    txt_value <- app$get_value(input = "txt")
    cap_value <- app$get_value(input = "caps")
    n_value <- app$get_value(input = "n")
    sum_value <- app$get_value(export = "sum")

    # initiate snapshot
    app$click("bookmark")
    app$wait_for_idle(500)



    app$stop()
  })
})


