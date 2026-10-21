# Severidad económica: cruce lote x bodega x fechas x mediciones x rebajas.
# Paso metodológico EXPLÍCITO (OE2): sin lote, bodega y fechas no hay cruce.
suppressPackageStartupMessages({ library(dplyr); library(purrr) })

# Horas sin corregir acumuladas por lote bajo un esquema de actualización
# (suma sobre los eventos de su bodega que empiezan durante la estancia).
exposicion_por_lote <- function(lotes, episodios, esquema) {
  ep <- episodios |>
    mutate(u = horas_sin_corregir(inicio, duracion_h, esquema))
  lotes |>
    mutate(horas_sin_corregir = pmap_dbl(
      list(sede_codigo, bodega, fecha_entrada, fecha_salida),
      function(s, b, f1, f2) {
        sel <- ep$sede_codigo == s & ep$logger == b &
          as.Date(ep$inicio) >= f1 & as.Date(ep$inicio) <= f2
        sum(ep$u[sel])
      }))
}

# Modelo de severidad: pct_rebaja = min(tope, k * horas^beta). Con beta = 1 es
# lineal y aditivo entre eventos (consistente con el nivel evento de la
# simulación). k se estima por mínimos cuadrados por el origen entre lotes sin
# tope; se reporta R^2 y n.
ajustar_severidad <- function(lotes_exp, beta = severidad$beta, tope = severidad$tope_pct) {
  x <- lotes_exp$horas_sin_corregir^beta
  y <- lotes_exp$pct_rebaja
  ok <- y < tope & x > 0
  k <- sum(x[ok] * y[ok]) / sum(x[ok]^2)
  pred <- pmin(tope, k * x)
  list(k = k, beta = beta, tope = tope, n = sum(ok), n_total = nrow(lotes_exp),
       r2 = 1 - sum((y - pred)^2) / sum((y - mean(y))^2))
}

pct_rebaja <- function(horas, modelo) pmin(modelo$tope, modelo$k * horas^modelo$beta)

# Ocupación de cada bodega: fracción del periodo observado con un lote
# almacenado (probabilidad de que un evento afecte café).
ocupacion_bodega <- function(lotes, dias_obs) {
  lotes |>
    mutate(dias = as.numeric(fecha_salida - fecha_entrada) + 1) |>
    group_by(sede_codigo, bodega) |>
    summarise(dias_ocupados = sum(dias), .groups = "drop") |>
    left_join(dias_obs, by = c("sede_codigo", "bodega" = "logger")) |>
    mutate(ocupacion = pmin(1, dias_ocupados / dias_obs))
}
