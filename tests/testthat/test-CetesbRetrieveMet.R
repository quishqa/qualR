test_that("CetesbRetrieveMet works", {

  load("sysdata.rda")

  pin_pol <- CetesbRetrieveMet(u,p,aqs_code = 99,
                               start_date   = "01/01/2020",
                               end_date     = "07/01/2020")

  expect_equal( ncol(pin_pol), 7)
})
