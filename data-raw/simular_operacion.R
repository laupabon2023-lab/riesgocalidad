#!/usr/bin/env Rscript
# Simula lotes, rebajas y operación SOBRE UN ARCHIVO DE MEDICIONES (sintético o
# real). Todo lo que genera es SIMULADO; si las mediciones son reales, las
# salidas se escriben en data/real/ (ignorada por Git) y NO se publican.
#
# Uso:
#   Rscript data-raw/simular_operacion.R <mediciones.csv> <nivel: logger|sede> <dir_salida>
#
# Diferencias con data-raw/simular_lotes.R (que es una prueba de recuperación):
#  - la rebaja NO se genera con el mismo modelo que se ajusta: depende de las
#    horas sin corregir bajo la operación SIMULADA (respuesta lognormal por sede,
#    demoras ocasionales), con curva de dosis-respuesta no lineal y saturada;
#  - parte de las rebajas tiene OTRAS causas (defectos, mezcla) no ambientales;
#  - el tiempo de respuesta varía entre sedes y entre eventos.
suppressPackageStartupMessages({ library(dplyr); library(readr) })
for (f in list.files("R", full.names = TRUE)) source(f)
args <- commandArgs(trailingOnly = TRUE)
ruta <- if (length(args) >= 1) args[1] else "data/sintetico/mediciones_sinteticas.csv"
nivel <- if (length(args) >= 2) args[2] else "logger"
salida <- if (length(args) >= 3) args[3] else "data/sintetico"
dir.create(salida, recursive = TRUE, showWarnings = FALSE)
set.seed(20261027)

# ---- Parámetros de la simulación (todos supuestos, editables) ----
p <- list(
  estancia_media_d = 12, estancia_sd_d = 5, estancia_min_d = 3,   # días que un lote está en bodega
  hueco_max_d = 4,                                                # días vacía entre lotes
  peso_media = 4000, peso_sd = 900, precio_media = 14000, precio_sd = 1500,
  tope = 0.25,                       # rebaja máxima por lote
  h50 = 150, gamma = 1.15,           # dosis-respuesta: pct = tope * (1 - exp(-(H/h50)^gamma))
  ruido_sd = 0.25,                   # ruido multiplicativo (lognormal)
  p_otras = 0.12, otras_rango = c(0.01, 0.06),   # rebajas por otras causas, no ambientales
  resp_mediana_h = c(3, 12), resp_sdlog = 0.6,   # mediana del tiempo de respuesta por sede ~ U(3,12) h
  p_demora = 0.10, demora_h = 48                 # 10 % de los eventos se demora 48 h más
)

m <- preparar_nivel(leer_mediciones(ruta), nivel)
m <- filtrar_imposibles(m)$datos
ep <- extraer_episodios(a_horario(clasificar_lecturas(m), "evento_critico"))
rango <- m |> group_by(sede_codigo, logger) |>
  summarise(d1 = as.Date(min(ts)), d2 = as.Date(max(ts)), .groups = "drop")

# ---- Operación simulada por sede ----
sedes <- sort(unique(rango$sede_codigo))
oper <- tibble(sede_codigo = sedes,
               dia_carga = "lunes", hora_carga = 8,
               resp_meanlog = log(runif(length(sedes), p$resp_mediana_h[1], p$resp_mediana_h[2])),
               resp_sdlog = p$resp_sdlog, p_demora = p$p_demora, demora_h = p$demora_h)
write_csv(oper, file.path(salida, "operacion_simulada.csv"))

# ---- Lotes por bodega ----
lotes <- bind_rows(lapply(seq_len(nrow(rango)), function(i) {
  r <- rango[i, ]; f <- r$d1 + sample(0:6, 1); out <- list()
  while (f < r$d2 - p$estancia_min_d) {
    dur <- max(p$estancia_min_d, round(rnorm(1, p$estancia_media_d, p$estancia_sd_d)))
    out[[length(out) + 1]] <- tibble(sede_codigo = r$sede_codigo, bodega = r$logger,
                                     fecha_entrada = f, fecha_salida = min(f + dur, r$d2))
    f <- f + dur + sample(0:p$hueco_max_d, 1)
  }
  bind_rows(out)
}))
n <- nrow(lotes)
lotes$lote_id <- sprintf("L%05d", seq_len(n))
lotes$peso_kg <- pmax(500, round(rnorm(n, p$peso_media, p$peso_sd)))
lotes$variedad <- sample(c("Castillo", "Caturra", "Colombia", "Tabi"), n, TRUE)
lotes$precio_base_kg <- pmax(8000, round(rnorm(n, p$precio_media, p$precio_sd)))

# ---- Horas sin corregir REALES de la operación simulada (esquema semanal) ----
oi <- setNames(seq_len(nrow(oper)), oper$sede_codigo)
ep$resp <- exp(rnorm(nrow(ep), oper$resp_meanlog[oi[ep$sede_codigo]], oper$resp_sdlog[oi[ep$sede_codigo]])) +
  (runif(nrow(ep)) < p$p_demora) * p$demora_h
ep$u <- pmin(ep$duracion_h, espera_hasta_refresco_h(ep$inicio, esquemas$semanal) + ep$resp)
lotes$H <- vapply(seq_len(n), function(i) {
  sel <- ep$sede_codigo == lotes$sede_codigo[i] & ep$logger == lotes$bodega[i] &
    as.Date(ep$inicio) >= lotes$fecha_entrada[i] & as.Date(ep$inicio) <= lotes$fecha_salida[i]
  sum(ep$u[sel])
}, numeric(1))

# ---- Rebaja: ambiental (no lineal, saturada) + otras causas + ruido ----
amb <- p$tope * (1 - exp(-(lotes$H / p$h50)^p$gamma)) * exp(rnorm(n, 0, p$ruido_sd))
otras <- ifelse(runif(n) < p$p_otras, runif(n, p$otras_rango[1], p$otras_rango[2]), 0)
lotes$pct_rebaja <- round(pmin(p$tope, amb + otras), 4)
lotes$causa_rebaja <- ifelse(lotes$pct_rebaja == 0, "ninguna",
                      ifelse(otras > 0 & amb < 0.005, "otras", ifelse(otras > 0, "mixta", "ambiental")))
lotes$valor_rebaja_cop <- round(lotes$pct_rebaja * lotes$peso_kg * lotes$precio_base_kg)
lotes <- lotes[, c("lote_id", "sede_codigo", "bodega", "fecha_entrada", "fecha_salida",
                   "peso_kg", "variedad", "precio_base_kg", "pct_rebaja", "causa_rebaja", "valor_rebaja_cop")]
write_csv(lotes, file.path(salida, "lotes_simulados.csv"))
cat("lotes:", n, "| bodegas:", nrow(rango), "| sin rebaja:", sum(lotes$pct_rebaja == 0), "\n")
print(table(lotes$causa_rebaja))
