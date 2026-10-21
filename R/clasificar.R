# Clasificación de lecturas horarias según los umbrales de negocio.
# Entrada: data frame con temperatura, humedad_relativa, punto_rocio, gpp.
# Salida: mismas filas + indicadores DESAGREGADOS por variable (no una
# etiqueta única de reporte, que agrupa categorías intermedias).

clasificar_lecturas <- function(df, u = umbrales) {
  stopifnot(all(c("temperatura", "humedad_relativa", "punto_rocio", "gpp") %in% names(df)))
  fuera <- function(x, rango) x < rango[1] | x > rango[2]
  df$alarma_gpp     <- fuera(df$gpp, u$gpp_seguro)
  df$gpp_saturado   <- df$gpp > u$gpp_critico
  df$alarma_hr      <- df$humedad_relativa > u$hr_seguro[2] | df$humedad_relativa < u$hr_seco
  df$alarma_temp    <- df$temperatura > u$temp_alta | df$temperatura < u$temp_baja
  df$condensacion   <- (df$temperatura - df$punto_rocio) <= u$margen_condensacion_c
  df$riesgo_humedad <- df$alarma_gpp | df$alarma_hr
  # Definición amplia (reporte): cualquier lectura fuera de la zona segura de
  # GPP o temperatura alta/condensación.
  df$alarma_amplia  <- df$alarma_gpp | df$temperatura > u$temp_alta | df$condensacion
  # Definición para el modelo: eventos críticos.
  df$evento_critico <- df$gpp_saturado | df$temperatura > u$temp_alta | df$condensacion
  df
}

# Filtra físicamente imposibles (temperatura < 0 °C, HR, GPP o punto de rocío
# iguales a 0) y devuelve conteos para trazabilidad.
filtrar_imposibles <- function(df) {
  malo <- df$temperatura < 0 | df$humedad_relativa <= 0 | df$gpp <= 0 | df$punto_rocio <= 0
  malo[is.na(malo)] <- TRUE
  list(datos = df[!malo, , drop = FALSE], n_descartados = sum(malo))
}
