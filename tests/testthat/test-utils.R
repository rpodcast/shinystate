test_that("session ID extracton from URL works", {
  url <- "http://127.0.0.1/?state_id_=1234567890fa"
  expect_identical(session_id_from_url(url), "1234567890fa")
})

