# Escenarios de actualización: cuánto tarda un evento en ser visible en el
# tablero y, por tanto, cuántas horas queda sin corregir.
#   horas_sin_corregir = min(duración del evento, espera hasta el próximo
#   refresco + tiempo de respuesta)
# Si el evento termina antes del refresco, el daño ya ocurrió completo.
suppressPackageStartupMessages(library(lubridate))

espera_hasta_refresco_h <- function(inicio, esquema = esquemas$semanal) {
  if (esquema$tipo == "tiempo_real") return(rep(esquema$latencia_h, length(inicio)))
  dia0 <- floor_date(inicio, "day")
  hora <- esquema$hora_carga
  if (esquema$tipo == "diaria") {
    prox <- dia0 + hours(hora)
    prox[prox <= inicio] <- prox[prox <= inicio] + days(1)
  } else if (esquema$tipo == "semanal") {
    # lunes = wday 2 con week_start = 7 (domingo=1); usamos week_start=1 -> lunes=1
    dsem <- wday(inicio, week_start = 1)             # 1 = lunes
    lunes <- dia0 - days(dsem - 1)
    prox <- lunes + hours(hora)
    prox[prox <= inicio] <- prox[prox <= inicio] + weeks(1)
  } else stop("esquema desconocido")
  as.numeric(difftime(prox, inicio, units = "hours"))
}

horas_sin_corregir <- function(inicio, duracion_h, esquema, respuesta = respuesta_h) {
  pmin(duracion_h, espera_hasta_refresco_h(inicio, esquema) + respuesta)
}
