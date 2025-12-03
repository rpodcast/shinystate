test_that("session ID extraction from URL works", {
  url <- "http://127.0.0.1/?_state_id_=1234567890fa"
  expect_identical(session_id_from_url(url), "1234567890fa")
})

test_that("importing an empty session board returns NULL", {
  storage_dir <- withr::local_tempdir()
  my_storage <- StorageClass$new(storage_dir)
  expect_true(is.null(import_sessions(my_storage$board_sessions)))
})

test_that("session metadata validation works", {
  # Valid metadata
  expect_true(validate_session_metadata(NULL))
  expect_true(validate_session_metadata(list(name = "test", value = 123)))

  # Invalid metadata - not a list
  expect_error(
    validate_session_metadata("not a list"),
    "session_metadata must be a named list"
  )

  # Invalid metadata - unnamed list
  expect_error(
    validate_session_metadata(list("unnamed")),
    "session_metadata must be a named list"
  )

  # Invalid metadata - multi-length element
  expect_error(
    validate_session_metadata(list(vals = c(1, 2, 3))),
    "must be single-length"
  )
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

  # verify upload to pins board with new metadata structure
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)
  upload_bookmark_bundle(
    local_storage_dir,
    url,
    board_sessions,
    session_metadata = list(test_field = "test_value")
  )

  # obtain metadata
  # TODO: Find way to use a generalized variable for name
  bundle_metadata <- pins::pin_meta(board_sessions, name = "500723aea64d9a8e")
  expect_equal(bundle_metadata$type, "file")
  expect_true("shiny_bookmark_id" %in% names(bundle_metadata$user))
  expect_true("timestamp" %in% names(bundle_metadata$user))
  expect_true("url" %in% names(bundle_metadata$user))
  expect_true("test_field" %in% names(bundle_metadata$user))
  expect_equal(bundle_metadata$user$test_field, "test_value")
  expect_identical(bundle_metadata$name, bundle_metadata$title)

  # verify download of bookmark bundle
  download_storage_dir <- withr::local_tempdir()
  download_bookmark_bundle(
    download_storage_dir,
    shiny_bookmark_id = "500723aea64d9a8e",
    board = board_sessions
  )

  expect_true(fs::dir_exists(fs::path(download_storage_dir, "shiny_bookmarks")))
  expect_true(fs::dir_exists(fs::path(
    download_storage_dir,
    "shiny_bookmarks",
    "500723aea64d9a8e"
  )))
  expect_true(fs::file_exists(fs::path(
    download_storage_dir,
    "shiny_bookmarks",
    "500723aea64d9a8e",
    "input.rds"
  )))
  expect_true(fs::file_exists(fs::path(
    download_storage_dir,
    "shiny_bookmarks",
    "500723aea64d9a8e",
    "values.rds"
  )))
})

test_that("importing sessions from bookmark metadata works", {
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)

  # Use existing fixture
  url1 <- "http://127.0.0.1:8888/?_state_id_=500723aea64d9a8e"
  local_storage_dir <- test_path("fixtures", "shinysessions")

  # Upload with session metadata
  upload_bookmark_bundle(
    local_storage_dir = local_storage_dir,
    url = url1,
    board = board_sessions,
    session_metadata = list(save_name = "Test Session", version = 1)
  )

  # Import and verify
  sessions_df <- import_sessions(board_sessions)
  expect_s3_class(sessions_df, "data.frame")
  expect_equal(nrow(sessions_df), 1L)
  expect_true("url" %in% names(sessions_df))
  expect_true("shiny_bookmark_id" %in% names(sessions_df))
  expect_true("timestamp" %in% names(sessions_df))
  expect_true("save_name" %in% names(sessions_df))
  expect_equal(sessions_df$save_name, "Test Session")
  expect_equal(sessions_df$version, 1)
})

test_that("deleting sessions works", {
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)
  local_storage_dir <- test_path("fixtures", "shinysessions")

  # Use existing fixture
  url <- "http://127.0.0.1:8888/?_state_id_=500723aea64d9a8e"
  upload_bookmark_bundle(
    local_storage_dir = local_storage_dir,
    url = url,
    board = board_sessions,
    session_metadata = list(name = "To Delete")
  )

  # Verify it exists
  expect_true("500723aea64d9a8e" %in% pins::pin_list(board_sessions))

  # Delete it
  delete_session(url, board_sessions)

  # Verify it's gone
  expect_false("500723aea64d9a8e" %in% pins::pin_list(board_sessions))
})

test_that("setting bookmark state options works", {
  storage_dir <- withr::local_tempdir()
  set_bookmark_options(storage_dir)

  expect_equal(shiny::getShinyOption("local_storage_dir"), storage_dir)
  expect_type(shiny::getShinyOption("save.interface"), "closure")
  expect_type(shiny::getShinyOption("load.interface"), "closure")
})

test_that("legacy sessions migration works", {
  storage_dir <- withr::local_tempdir()
  board_sessions <- pins::board_folder(storage_dir)
  local_storage_dir <- test_path("fixtures", "shinysessions")

  # First, upload the existing fixture as a bookmark
  url_fixture <- "http://127.0.0.1:8888/?_state_id_=500723aea64d9a8e"
  bundle_path <- create_bookmark_bundle(local_storage_dir, url_fixture)

  # Upload with OLD metadata structure (no url field, to simulate legacy)
  old_meta <- list(
    shiny_bookmark_id = "500723aea64d9a8e",
    timestamp = Sys.time()
  )

  suppressMessages(
    pins::pin_upload(
      board = board_sessions,
      paths = bundle_path,
      name = "500723aea64d9a8e",
      title = "500723aea64d9a8e",
      metadata = old_meta
    )
  )
  unlink(bundle_path)

  # Create a legacy "sessions" pin with metadata for this bookmark
  legacy_sessions <- data.frame(
    url = "?_state_id_=500723aea64d9a8e",
    save_name = "Legacy Session Test",
    stringsAsFactors = FALSE
  )
  pins::pin_write(board_sessions, legacy_sessions, name = "sessions")

  # Verify legacy pin exists
  expect_true("sessions" %in% pins::pin_list(board_sessions))

  # Verify bookmark has old metadata (no url field)
  old_bookmark_meta <- pins::pin_meta(board_sessions, "500723aea64d9a8e")
  expect_true(is.null(old_bookmark_meta$user$url))

  # Trigger migration by importing sessions
  expect_message(
    sessions_df <- import_sessions(board_sessions),
    "Migrating legacy session metadata"
  )

  # Verify migration results
  expect_false("sessions" %in% pins::pin_list(board_sessions))  # Legacy pin deleted
  expect_s3_class(sessions_df, "data.frame")
  expect_equal(nrow(sessions_df), 1L)
  expect_true(all(c("url", "save_name", "shiny_bookmark_id") %in% names(sessions_df)))
  expect_equal(sessions_df$save_name, "Legacy Session Test")

  # Verify migrated metadata in bookmark pin
  new_meta <- pins::pin_meta(board_sessions, "500723aea64d9a8e")
  expect_true(!is.null(new_meta$user$url))
  expect_equal(new_meta$user$url, "?_state_id_=500723aea64d9a8e")
  expect_equal(new_meta$user$save_name, "Legacy Session Test")

  # Second import should not trigger migration again
  expect_silent(sessions_df2 <- import_sessions(board_sessions))
  expect_equal(nrow(sessions_df2), 1L)
})
