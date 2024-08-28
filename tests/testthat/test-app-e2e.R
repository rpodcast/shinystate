library(shiny)
library(shinytest2)

test_that("Bookmark saving works end-to-end", {
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
  storage_dir <- app_save$get_value(export = "storage_rv")

  # initiate snapshot and stop application
  app_save$click("bookmark")
  app_save$wait_for_idle(500)
  app_save$stop()

  # TODO: Cannot figure out how to get exported values after clicking restore button
  # obtain sessions metadata to get restore URL
  sessions_df <- import_sessions(board_save)
  session_id <- session_id_from_url(sessions_df$url)

  # obtain restored values
  # TODO: Grab these from bookmark state files directly
  # unable to grab these from the shiny server process
  input_obj <- readRDS(fs::path(storage_dir, "shiny_bookmarks", session_id, "input.rds"))
  values_env <- readRDS(fs::path(storage_dir, "shiny_bookmarks", session_id, "values.rds"))

  expect_equal(txt_value_save, input_obj[["txt"]])
  expect_equal(cap_value_save, input_obj[["caps"]])
  expect_equal(n_value_save, input_obj[["n"]])
  expect_equal(sum_value_save, values_env[["currentSum"]])

  # rempve all bookmark artifacts
  fs::dir_delete(fs::path(storage_dir, "shiny_bookmarks"))
  fs::dir_delete(fs::path(storage_dir, "sessions"))
  fs::dir_delete(fs::path(storage_dir, session_id))
})
