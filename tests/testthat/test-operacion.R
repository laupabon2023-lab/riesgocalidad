test_that("es_exterior detecta sensores exteriores por nombre", {
  expect_true(all(es_exterior(c("Exterior Are", "EXT-B5-S1-MAYO", "DATA EXTERNO", "Zon_EXTERIOR_PU", "RB BOD4 EXT"))))
  expect_false(any(es_exterior(c("Bodega 1 Are", "B-1A-S1-MAYO", "bodega excelso", "RB BOD2 IZQ1"))))
})
test_that("preparar_nivel(sede) excluye exteriores y unifica por sede", {
  m <- data.frame(sede_codigo = c("RA", "RA", "RB"), logger = c("Bodega 1", "EXT.", "RB BOD1"), stringsAsFactors = FALSE)
  r <- preparar_nivel(m, "sede")
  expect_equal(nrow(r), 2)
  expect_equal(r$logger, c("RA", "RB"))
  expect_equal(preparar_nivel(m, "logger"), m)
})
test_that("respuesta_media_h combina lognormal y demoras", {
  o <- data.frame(resp_meanlog = log(4), resp_sdlog = 0, p_demora = 0.1, demora_h = 48)
  expect_equal(respuesta_media_h(o), 4 + 4.8)
})
