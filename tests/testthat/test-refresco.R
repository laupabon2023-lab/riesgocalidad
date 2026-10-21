# 2026-03-02 es lunes
lun <- as.POSIXct("2026-03-02 00:00:00", tz = "UTC")
test_that("espera semanal: hasta el próximo lunes a la hora de carga", {
  e <- esquemas$semanal  # lunes 08:00
  expect_equal(espera_hasta_refresco_h(lun + 3600 * 2, e), 6)                     # lun 02:00 -> 08:00
  expect_equal(espera_hasta_refresco_h(lun + 3600 * 9, e), 7 * 24 - 1)            # lun 09:00 -> lun sig 08:00
  expect_equal(espera_hasta_refresco_h(lun + 5 * 24 * 3600, e), 2 * 24 + 8)       # sábado 00:00 -> lunes 08:00
})
test_that("espera diaria y en tiempo real", {
  expect_equal(espera_hasta_refresco_h(lun + 3600 * 2, esquemas$diaria), 6)
  expect_equal(espera_hasta_refresco_h(lun + 3600 * 9, esquemas$diaria), 23)
  expect_equal(espera_hasta_refresco_h(lun, esquemas$tiempo_real), 1)
})
test_that("horas sin corregir: nunca exceden la duración y bajan con refresco más frecuente", {
  ini <- lun + 3600 * (0:150)
  dur <- rep(40, length(ini))
  u_s <- horas_sin_corregir(ini, dur, esquemas$semanal, 4)
  u_d <- horas_sin_corregir(ini, dur, esquemas$diaria, 4)
  u_r <- horas_sin_corregir(ini, dur, esquemas$tiempo_real, 4)
  expect_true(all(u_s <= dur) && all(u_d <= u_s + 1e-9) && all(u_r <= u_d + 1e-9))
  # evento corto que termina antes del refresco: daño completo
  expect_equal(horas_sin_corregir(lun + 3600 * 1, 3, esquemas$semanal, 4), 3)
})
