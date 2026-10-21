test_that("VaR y CVaR: CVaR >= VaR >= cuantil; valores conocidos", {
  x <- 1:100
  r <- var_cvar(x, 0.95)
  expect_equal(unname(r["VaR"]), unname(quantile(x, 0.95)))
  expect_gte(r["CVaR"], r["VaR"])
  expect_equal(unname(r["CVaR"]), mean(x[x >= quantile(x, 0.95)]))
})
test_that("la severidad respeta el tope y es monótona", {
  m <- list(k = 0.001, beta = 1, tope = 0.25)
  expect_equal(pct_rebaja(c(0, 100, 1e6), m), c(0, 0.1, 0.25))
})
test_that("el ajuste recupera un coeficiente conocido", {
  set.seed(1); h <- runif(400, 5, 150); y <- 0.0005 * h + rnorm(400, 0, 0.004)
  mod <- ajustar_severidad(data.frame(horas_sin_corregir = h, pct_rebaja = pmax(0, y)))
  expect_equal(mod$k, 0.0005, tolerance = 0.05)
})
test_that("la simulación es reproducible y ordena los esquemas", {
  ep <- data.frame(sede_codigo = "S", logger = "B",
                   inicio = as.POSIXct("2026-03-02 00:00:00", tz = "UTC") + 3600 * c(3, 30, 60, 100, 130),
                   duracion_h = c(50, 80, 20, 100, 10))
  lotes <- data.frame(peso_kg = c(4000, 3000), precio_base_kg = c(14000, 15000))
  ocup <- data.frame(sede_codigo = "S", bodega = "B", ocupacion = 0.8)
  freq <- data.frame(sede_codigo = "S", logger = "B", mu = 30)
  mod <- list(k = 0.0005, beta = 1, tope = 0.25)
  a <- simular_perdida_anual(ep, lotes, ocup, freq, Inf, mod, n_sim = 500, semilla = 7)
  b <- simular_perdida_anual(ep, lotes, ocup, freq, Inf, mod, n_sim = 500, semilla = 7)
  expect_identical(a, b)
  expect_true(all(a[, "diaria"] <= a[, "semanal"] + 1e-6))
  expect_true(all(a[, "tiempo_real"] <= a[, "diaria"] + 1e-6))
})
