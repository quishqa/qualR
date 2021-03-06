test_that("MonitorArRetrieve works", {

  dir.create(file.path(tempdir(), "cetesb-data"))
  setwd(file.path(tempdir(), "cetesb-data"))

  ca_o3 <- MonitorArRetrieve(start_date = "01/02/2015",
                             end_date   = "01/03/2015",
                             aqs_code   = "CA",
                             param      = "O3",
                             to_csv     = TRUE)

  expect_equal(ncol(ca_o3),3)
})
