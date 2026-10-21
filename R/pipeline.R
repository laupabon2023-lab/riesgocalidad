# Pipeline completo OE1 -> OE4. Un solo punto de entrada: ejecutar_pipeline().
suppressPackageStartupMessages({ library(dplyr); library(readr); library(lubridate) })

leer_mediciones <- function(ruta, anio = 2026) {
  d <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE)
  if (!"logger" %in% names(d) && "logging_name" %in% names(d)) d$logger <- d$logging_name
  req <- c("sede_codigo", "logger", "fecha_hora", "temperatura", "humedad_relativa", "punto_rocio", "gpp")
  faltan <- setdiff(req, names(d))
  if (length(faltan)) stop("Faltan columnas en mediciones: ", paste(faltan, collapse = ", "))
  d$ts <- as.POSIXct(d$fecha_hora, tz = "UTC")  # hora local naive
  d <- d[!is.na(d$ts) & lubridate::year(d$ts) == anio, c("sede_codigo", "logger", "ts", req[4:7])]
  d
}

leer_lotes <- function(ruta) {
  l <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE)
  req <- c("lote_id", "sede_codigo", "bodega", "fecha_entrada", "fecha_salida",
           "peso_kg", "precio_base_kg", "pct_rebaja")
  faltan <- setdiff(req, names(l))
  if (length(faltan)) stop("Faltan columnas en lotes: ", paste(faltan, collapse = ", "))
  l$fecha_entrada <- as.Date(l$fecha_entrada); l$fecha_salida <- as.Date(l$fecha_salida)
  l
}

ejecutar_pipeline <- function(ruta_mediciones, ruta_lotes, dir_salida,
                              etiqueta = "SINTETICO", n_sim = sim$n_sim,
                              semilla = sim$semilla, verbose = TRUE) {
  say <- function(...) if (verbose) message(...)
  dir.create(dir_salida, recursive = TRUE, showWarnings = FALSE)
  guardar <- function(x, nombre) readr::write_csv(x, file.path(dir_salida, nombre))

  say("[OE1] Leyendo y clasificando mediciones")
  m <- leer_mediciones(ruta_mediciones)
  f <- filtrar_imposibles(m)
  m <- clasificar_lecturas(f$datos)
  hor <- a_horario(m, "evento_critico")
  ep <- extraer_episodios(hor)
  dias_obs <- m |> group_by(sede_codigo, logger) |>
    summarise(dias_obs = as.numeric(difftime(max(ts), min(ts), units = "days")), .groups = "drop")

  control <- tibble::tibble(
    etiqueta = etiqueta, n_lecturas = nrow(m), n_imposibles_descartados = f$n_descartados,
    pct_alarma_amplia = mean(m$alarma_amplia), pct_evento_critico = mean(m$evento_critico),
    n_episodios = nrow(ep), n_bodegas = n_distinct(m$sede_codigo, m$logger))
  guardar(control, "oe1_control.csv")
  guardar(resumen_alarmas(m), "oe1_alarmas_por_sede.csv")
  guardar(duracion_eventos(ep), "oe1_duracion_por_bodega.csv")
  guardar(as.data.frame(ajustar_duracion(ep$duracion_h)), "oe1_ajuste_duracion.csv")
  fm <- frecuencia_mensual(ep, dias_obs)
  guardar(fm, "oe1_frecuencia_mensual.csv")

  say("[OE2] Cruce lote-bodega-fechas y severidad")
  lotes <- leer_lotes(ruta_lotes)
  lotes_exp <- exposicion_por_lote(lotes, ep, esquemas$semanal)
  modelo <- ajustar_severidad(lotes_exp)
  guardar(as.data.frame(modelo), "oe2_modelo_severidad.csv")
  guardar(lotes_exp, "oe2_lotes_con_exposicion.csv")
  ocup <- ocupacion_bodega(lotes, dias_obs |> rename(dias_obs = dias_obs))
  # frecuencia anual esperada por bodega y sobredispersión (bodega-mes)
  freq <- ep |> count(sede_codigo, logger, name = "n") |>
    left_join(dias_obs, by = c("sede_codigo", "logger")) |>
    mutate(mu = n * 365 / pmax(dias_obs, 1))
  nb <- dispersion_nb(fm$n / fm$dias_obs * 30)  # conteo estandarizado a 30 días
  guardar(as.data.frame(nb), "oe2_dispersion_frecuencia.csv")
  tot <- simular_perdida_anual(ep, lotes, ocup, freq, nb$size, modelo, n_sim = n_sim, semilla = semilla)
  riesgo <- resumen_riesgo(tot)
  guardar(riesgo, "oe2_oe3_riesgo_por_esquema.csv")

  say("[OE3] Sensibilidad a supuestos")
  sens <- list()
  for (b in c(1, 1.3)) for (r in c(1, 4, 12)) {
    mod_b <- ajustar_severidad(lotes_exp, beta = b)
    tb <- simular_perdida_anual(ep, lotes, ocup, freq, nb$size, mod_b,
                                n_sim = min(n_sim, 3000), semilla = semilla, respuesta = r)
    rb <- resumen_riesgo(tb, B = 50); rb$beta <- b; rb$respuesta_h <- r
    sens[[length(sens) + 1]] <- rb
  }
  guardar(bind_rows(sens), "oe3_sensibilidad.csv")
  say("Listo. Salidas en ", dir_salida)
  invisible(list(control = control, modelo = modelo, riesgo = riesgo, episodios = ep, tot = tot))
}
