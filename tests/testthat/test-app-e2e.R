# hello_app <- function() {
#   ui <- function(request) {
#     fluidPage(
#       use_shinystate(),
#       textInput("txt", "Enter text"),
#       checkboxInput("caps", "Capitalize"),
#       sliderInput("n", "Value to add", min = 0, max = 100, value = 50),
#       actionButton("add", "Add"),
#       verbatimTextOutput("out"),
#       actionButton("bookmark", "Bookmark"),
#       actionButton("restore", "Restore Last Bookmark")
#     )
#   }

#   server <- function(input, output, session) {
#     storage <- StorageClass$new()
#     storage$register_metadata()

#     vals <- reactiveValues(sum = 0)
#     storage_rv <- reactiveVal(storage$local_storage_dir)
#     board_rv <- reactiveVal(storage$board_sessions)

#     onBookmark(function(state) {
#       state$values$currentSum <- vals$sum
#     })

#     onRestore(function(state) {
#       vals$sum <- state$values$currentSum
#     })

#     observeEvent(input$add, {
#       vals$sum <- vals$sum + input$n
#     })

#     output$out <- renderText({
#       if (input$caps) {
#         text <- toupper(input$txt)
#       } else {
#         text <- input$txt
#       }
#       glue::glue(
#         "current text: {text}
#         sum of all previous slider values: {vals$sum}"
#       )
#     })

#     observeEvent(input$bookmark, {
#       storage$snapshot()
#       showNotification("Session successfully saved", duration = NULL)
#     })

#     observeEvent(input$restore, {
#       session_df <- storage$get_sessions()
#       storage$restore(tail(session_df$url, n = 1))
#     })

#     setBookmarkExclude(c("add", "bookmark", "restore"))

#     exportTestValues(
#       storage_rv = { storage_rv() },
#       sum = vals$sum,
#       board_rv = { board_rv() }
#     )
#   }

#   shinyApp(ui, server, enableBookmarking = "server")
# }
library(shinytest2)

test_that("Bookmark saving works end-to-end", {
  library(shiny)
  withr::with_libpaths("../../prototyping/tmp_lib", {
    app_save <- AppDriver$new(
      "apps/basic",
      name = "shinystate-test-app-save",
      expect_values_screenshot_args = FALSE
    )

    app_url <- app_save$get_url()

    # enter sample text
    app_save$set_inputs(txt = "shinystate")
    app_save$wait_for_idle(500)
    app_save$set_inputs(caps = TRUE)
    app_save$wait_for_idle(500)

    # enter new slider value
    app_save$set_inputs(n = 75)
    app_save$wait_for_idle(500)
    app_save$click("add")
    app_save$wait_for_idle(500)

    # obtain current values for comparison
    txt_value_save <- app_save$get_value(input = "txt")
    cap_value_save <- app_save$get_value(input = "caps")
    n_value_save <- app_save$get_value(input = "n")
    sum_value_save <- app_save$get_value(export = "sum")
    board_save <- app_save$get_value(export = "board_rv")

    # initiate snapshot and stop application
    app_save$click("bookmark")
    app_save$wait_for_idle(500)
    app_save$stop()

    # TODO: Cannot figure out how to get exported values after clicking restore button
    # obtain sessions metadata to get restore URL
    sessions_df <- import_sessions(board_save)
    restore_url <- sessions_df$url

    # launch second instance of application
    app_restore <- AppDriver$new(
      #"http://127.0.0.1:5387?_state_id_=a4ae44b46744a797",
      "apps/basic",
      #paste0(app_url, restore_url),
      name = "shinystate-test-app-restore",
      expect_values_screenshot_args = FALSE
    )

    # click restore button
    app_restore$click("restore")
    Sys.sleep(2)

    # obtain restored values
    txt_value_restore <- app_restore$get_value(input = "txt")
    cap_value_restore <- app_restore$get_value(input = "caps")
    n_value_restore <- app_restore$get_value(input = "n")
    sum_value_restore <- app_restore$get_value(export = "sum")

    expect_equal(txt_value_save, txt_value_restore)
    expect_equal(cap_value_save, cap_value_restore)
    expect_equal(n_value_save, n_value_restore)
    expect_equal(sum_value_save, sum_value_restore)

    app_restore$stop()
  })
})


