test_that("los umbrales de la tabla se aplican por variable", {
  d <- data.frame(temperatura = c(18, 30, 18, 18), humedad_relativa = c(60, 60, 60, 60),
                  punto_rocio = c(10, 10, 17.5, 10), gpp = c(60, 60, 60, 105))
  r <- clasificar_lecturas(d)
  expect_equal(r$alarma_temp, c(FALSE, TRUE, FALSE, FALSE))
  expect_equal(r$condensacion, c(FALSE, FALSE, TRUE, FALSE))   # 18 - 17.5 <= 2
  expect_equal(r$gpp_saturado, c(FALSE, FALSE, FALSE, TRUE))
  expect_equal(r$evento_critico, c(FALSE, TRUE, TRUE, TRUE))
  expect_equal(r$alarma_gpp, c(FALSE, FALSE, FALSE, TRUE))
})
test_that("filtrar_imposibles quita temperatura < 0 y ceros", {
  d <- data.frame(temperatura = c(20, -5, 20), humedad_relativa = c(60, 60, 0),
                  punto_rocio = c(10, 10, 10), gpp = c(80, 80, 80))
  r <- filtrar_imposibles(d)
  expect_equal(nrow(r$datos), 1); expect_equal(r$n_descartados, 2)
})
test_that("falta de columnas falla con error claro", {
  expect_error(clasificar_lecturas(data.frame(x = 1)))
})
