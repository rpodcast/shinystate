test_that("session ID extracton from URL works", {
  url <- "http://127.0.0.1/?state_id_=1234567890fa"
  expect_identical(session_id_from_url(url), "1234567890fa")
})

test_that("importing an empty session board returns NULL", {
  storage_dir <- withr::local_tempdir()
  my_storage <- StorageClass$new(storage_dir)
  expect_true(empty_sessions(my_storage$board_sessions))
  expect_true(is.null(import_sessions(my_storage$board_sessions)))
})

test_that("creating session data set with metadata works", {
  # url after the sub looks like this: "?_state_id_=0375ff6d5aa8e12d"
  # url before the sub looks like this: "http://127.0.0.1:3947/?_state_id_=0375ff6d5aa8e12d"
  # df (with originally null session_metadata) is a one column tibble
  # with url as the only column
  expect_true(TRUE)

  # create fake url
  url <- "http://127.0.0.1:8888/?_state_id_=1234567890fa"

  # no metadata
  df <- create_session_data(url)
  expect_equal(nrow(df), 1L)
  expect_identical(names(df), "url")

  # mixture of metadata
  session_metadata <- list(
    save_name = "session1",
    timestamp = as.POSIXct("2024-08-30 01:00:00", tz = "UTC"),
    version = 1
  )

  df <- create_session_data(url, session_metadata)
  expect_equal(ncol(df), 4)
  expect_identical(names(df), c("url", "save_name", "timestamp", "version"))
  expect_type(df[["version"]], "double")
  expect_type(df[["timestamp"]], "double")
  expect_type(df[["save_name"]], "character")
})

test_that("uploading session data to pins board works", {
  # create sample session data
  url <- "http://127.0.0.1:8888/?_state_id_=1234567890fa"
  df <- create_session_data(url)

  # create temporary directory for local pins board
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)

  # upload session data
  upload_sessions(df, board_sessions)
  expect_equal(pins::pin_list(board_sessions), "sessions")

  # verify import of session data
  import_df <- import_sessions(board_sessions)
  expect_s3_class(import_df, "data.frame")
  expect_equal(nrow(import_df), 1L)
})