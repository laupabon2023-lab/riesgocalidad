# Genera lotes y rebajas SINTÉTICOS para poder probar el cruce y el modelo.
# La rebaja se genera con un coeficiente CONOCIDO (k_verdadero) a partir de las
# horas sin corregir que el propio pipeline calcula sobre las mediciones
# sintéticas. Por eso sirve como PRUEBA DE RECUPERACIÓN de parámetros (el
# ajuste debe devolver ~k_verdadero), NO como hallazgo sobre Racafé.
suppressPackageStartupMessages(library(dplyr))
for (f in list.files("R", full.names = TRUE)) source(f)
set.seed(20260102)
k_verdadero <- 0.0005          # fracción de rebaja por hora sin corregir
sd_ruido    <- 0.006

m  <- leer_mediciones("data/sintetico/mediciones_sinteticas.csv")
ep <- extraer_episodios(a_horario(clasificar_lecturas(m)))
bod <- distinct(m, sede_codigo, logger)

lotes <- bind_rows(lapply(seq_len(nrow(bod)), function(i) {
  f <- as.Date("2026-02-01") + sample(0:6, 1); out <- list()
  while (f < as.Date("2026-09-10")) {
    dur <- max(2, round(rnorm(1, 9, 3)))
    out[[length(out) + 1]] <- data.frame(sede_codigo = bod$sede_codigo[i], bodega = bod$logger[i],
                                         fecha_entrada = f, fecha_salida = f + dur)
    f <- f + dur + sample(0:4, 1)
  }
  do.call(rbind, out)
}))
n <- nrow(lotes)
lotes$lote_id <- sprintf("L%04d", seq_len(n))
lotes$peso_kg <- round(rnorm(n, 4000, 900))
lotes$variedad <- sample(c("Castillo", "Caturra", "Colombia", "Tabi"), n, TRUE)
lotes$precio_base_kg <- round(rnorm(n, 14000, 1500))
lotes <- exposicion_por_lote(lotes, ep, esquemas$semanal)
lotes$pct_rebaja <- round(pmin(0.25, pmax(0, k_verdadero * lotes$horas_sin_corregir + rnorm(n, 0, sd_ruido))), 4)
lotes$valor_rebaja_cop <- round(lotes$pct_rebaja * lotes$peso_kg * lotes$precio_base_kg)
lotes <- lotes[, c("lote_id", "sede_codigo", "bodega", "fecha_entrada", "fecha_salida",
                   "peso_kg", "variedad", "precio_base_kg", "pct_rebaja", "valor_rebaja_cop")]
write.csv(lotes, "data/sintetico/lotes_sinteticos.csv", row.names = FALSE)
cat("lotes:", n, " k_verdadero =", k_verdadero, "\n")
