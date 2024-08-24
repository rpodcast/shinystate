test_that("initialization works", {
  storage_dir <- withr::local_tempdir()
  my_storage <- StorageClass$new(storage_dir)
  expect_true(!is.null(my_storage$local_storage_dir))
  expect_s3_class(my_storage$board_sessions, "pins_board")
})
