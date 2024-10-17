test_that("session ID extracton from URL works", {
  url <- "http://127.0.0.1/?_state_id_=1234567890fa"
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

test_that("managing session data on pins board works", {
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

  # verify deletion of session data
  delete_session(url, board_sessions)
  expect_true(empty_sessions(board_sessions))
})

test_that("managing bookmark bundles works", {
  # create fake url with state id matching fixture
  # TODO: Find way to generalize this
  url <- "http://127.0.0.1:8888/?_state_id_=500723aea64d9a8e"

  # define storage directory of previously-generated bookmark files
  local_storage_dir <- test_path("fixtures", "shinysessions")

  # create bundle
  bundle_path <- create_bookmark_bundle(local_storage_dir, url)

  # verify contents of archive
  extract_dir <- withr::local_tempdir()
  archive::archive_extract(bundle_path, dir = extract_dir)
  input_obj <- readRDS(fs::path(extract_dir, "input.rds"))

  expect_equal(input_obj$n, 60)
  expect_true(!input_obj$caps)
  expect_equal(input_obj$txt, "silly")

  # verify upload to pins board
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)
  upload_bookmark_bundle(local_storage_dir, url, board_sessions)

  # obtain metadata
  # TODO: Find way to use a generalized variable for name
  bundle_metadata <- pins::pin_meta(board_sessions, name = "500723aea64d9a8e")
  expect_equal(bundle_metadata$type, "file")
  expect_identical(names(bundle_metadata$user), c("shiny_bookmark_id", "timestamp"))
  expect_identical(bundle_metadata$name, bundle_metadata$title)

  # verify download of bookmark bundle
  download_storage_dir <- withr::local_tempdir()
  download_bookmark_bundle(download_storage_dir, shiny_bookmark_id = "500723aea64d9a8e", board = board_sessions)

  expect_true(fs::dir_exists(fs::path(download_storage_dir, "shiny_bookmarks")))
  expect_true(fs::dir_exists(fs::path(download_storage_dir, "shiny_bookmarks", "500723aea64d9a8e")))
  expect_true(fs::file_exists(fs::path(download_storage_dir, "shiny_bookmarks", "500723aea64d9a8e", "input.rds")))
  expect_true(fs::file_exists(fs::path(download_storage_dir, "shiny_bookmarks", "500723aea64d9a8e", "values.rds")))
})

test_that("setting bookmark state options works", {
  storage_dir <- withr::local_tempdir()
  set_bookmark_options(storage_dir)

  expect_equal(shiny::getShinyOption("local_storage_dir"), storage_dir)
  expect_type(shiny::getShinyOption("save.interface"), "closure")
  expect_type(shiny::getShinyOption("load.interface"), "closure")
})