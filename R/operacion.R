# Unidad de análisis y datos de operación.
#
# Sensores EXTERIORES (EXT, EXTERIOR, EXTERNA/O): miden el ambiente de fuera,
# no el café; se excluyen del análisis de bodegas.
es_exterior <- function(nombre) grepl("EXT", toupper(nombre), fixed = TRUE)

# nivel = "logger": una bodega por datalogger (datos limpios con nombres estables,
#                   como los sintéticos).
# nivel = "sede"  : una bodega por sede. Se usa con los datos reales, cuyos
#                   nombres de logger son inconsistentes (cientos de nombres para
#                   pocos puntos físicos) y no hay mapa logger -> bodega. Se excluyen
#                   los sensores exteriores y se marca crítica la hora si CUALQUIER
#                   sensor interior de la sede lo está.
preparar_nivel <- function(m, nivel = c("logger", "sede")) {
  nivel <- match.arg(nivel)
  if (nivel == "logger") return(m)
  m <- m[!es_exterior(m$logger), , drop = FALSE]
  m$logger <- m$sede_codigo
  m
}

# Información operativa: por sede, día/hora de carga del tablero y distribución
# del tiempo de respuesta (horas entre que el dato es visible y se corrige).
leer_operacion <- function(ruta) {
  o <- readr::read_csv(ruta, show_col_types = FALSE, progress = FALSE)
  req <- c("sede_codigo", "resp_meanlog", "resp_sdlog", "p_demora", "demora_h")
  faltan <- setdiff(req, names(o))
  if (length(faltan)) stop("Faltan columnas en operacion: ", paste(faltan, collapse = ", "))
  o
}

# Media del tiempo de respuesta: lognormal + demora ocasional (promedio entre sedes).
respuesta_media_h <- function(o) {
  mean(exp(o$resp_meanlog + o$resp_sdlog^2 / 2) + o$p_demora * o$demora_h)
}
