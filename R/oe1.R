# OE1: caracterización de frecuencia y duración de alarmas por trilladora y
# bodega, separando humedad/secado de condensación.
suppressPackageStartupMessages({ library(dplyr); library(tidyr) })

resumen_alarmas <- function(df) {
  # Proporción de horas-registro en cada tipo de condición, por sede.
  df |>
    group_by(sede_codigo) |>
    summarise(
      n_lecturas = n(),
      pct_alarma_amplia = mean(alarma_amplia),
      pct_riesgo_humedad = mean(riesgo_humedad),
      pct_temp_alta = mean(temperatura > umbrales$temp_alta),
      pct_condensacion = mean(condensacion),
      pct_evento_critico = mean(evento_critico),
      .groups = "drop"
    )
}

duracion_eventos <- function(episodios) {
  episodios |>
    group_by(sede_codigo, logger) |>
    summarise(n_eventos = n(),
              dur_mediana_h = median(duracion_h),
              dur_p90_h = unname(quantile(duracion_h, 0.9)),
              dur_max_h = max(duracion_h), .groups = "drop")
}

# Frecuencia mensual de eventos por bodega y su sobredispersión
# (var/media > 1 => binomial negativa mejor que Poisson).
frecuencia_mensual <- function(episodios, dias_observados) {
  episodios |>
    mutate(mes = format(inicio, "%Y-%m")) |>
    count(sede_codigo, logger, mes, name = "n") |>
    left_join(dias_observados, by = c("sede_codigo", "logger"))
}

dispersion_nb <- function(conteos) {
  m <- mean(conteos); v <- var(conteos)
  if (is.na(v) || v <= m) return(list(media = m, var = v, size = Inf))  # Poisson
  list(media = m, var = v, size = m^2 / (v - m))
}

# Ajuste de la duración de eventos (lognormal vs gamma por AIC).
ajustar_duracion <- function(duracion_h) {
  x <- duracion_h[duracion_h > 0]
  ln <- MASS::fitdistr(x, "lognormal")
  gm <- suppressWarnings(MASS::fitdistr(x, "gamma", start = list(shape = 1, rate = 1 / mean(x)), lower = 1e-6))
  data.frame(modelo = c("lognormal", "gamma"),
             aic = c(AIC(ln), AIC(gm)),
             par1 = c(ln$estimate[1], gm$estimate[1]),
             par2 = c(ln$estimate[2], gm$estimate[2]))
}
