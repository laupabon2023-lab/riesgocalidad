mk <- function(horas, flags, logger = "L1") {
  data.frame(sede_codigo = "S", logger = logger,
             ts = as.POSIXct("2026-03-02 00:00:00", tz = "UTC") + horas * 3600,
             evento_critico = flags)
}
test_that("rachas consecutivas forman un episodio y una hora faltante lo corta", {
  d <- mk(c(0, 1, 2, 3, 4, 5, 7, 8), c(TRUE, TRUE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE))
  ep <- extraer_episodios(a_horario(d))
  expect_equal(ep$duracion_h, c(2, 3, 2))   # 0-1 ; 3-5 ; (6 falta) 7-8
})
test_that("lecturas dentro de la misma hora se resumen con any()", {
  d <- mk(c(0, 0.5, 1), c(FALSE, TRUE, TRUE))
  ep <- extraer_episodios(a_horario(d))
  expect_equal(ep$duracion_h, 2)
})
test_that("loggers distintos no se mezclan", {
  d <- rbind(mk(0:2, rep(TRUE, 3), "A"), mk(0:2, rep(TRUE, 3), "B"))
  expect_equal(nrow(extraer_episodios(a_horario(d))), 2)
})
