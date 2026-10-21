# De lecturas a eventos: rachas de horas consecutivas en condición crítica
# por datalogger (bodega). Insumo de OE1 y de la frecuencia del modelo.
suppressPackageStartupMessages({ library(dplyr); library(lubridate) })

a_horario <- function(df, flag = "evento_critico") {
  # Una fila por (logger, hora): el flag vale TRUE si alguna lectura de esa
  # hora lo cumple (las lecturas reales no siempre son exactamente horarias).
  df |>
    mutate(hora = floor_date(ts, "hour")) |>
    group_by(sede_codigo, logger, hora) |>
    summarise(flag = any(.data[[flag]]), .groups = "drop") |>
    arrange(sede_codigo, logger, hora)
}

extraer_episodios <- function(horario) {
  horario |>
    group_by(sede_codigo, logger) |>
    mutate(
      salto = c(TRUE, diff(as.numeric(hora)) > 3600),   # hora faltante = corte
      cambio = salto | c(TRUE, flag[-1] != flag[-n()]),
      racha = cumsum(cambio)
    ) |>
    filter(flag) |>
    group_by(sede_codigo, logger, racha) |>
    summarise(inicio = min(hora), fin = max(hora) + 3600,
              duracion_h = n(), .groups = "drop") |>
    select(-racha)
}
