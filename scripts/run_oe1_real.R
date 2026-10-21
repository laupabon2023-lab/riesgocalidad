#!/usr/bin/env Rscript
# OE1 sobre mediciones REALES, solo en local. Uso:
#   RACAFE_MEDICIONES=/ruta/mediciones.csv Rscript scripts/run_oe1_real.R
# Escribe en outputs/real/ (ignorada por git). No requiere lotes ni rebajas.
for (f in list.files("R", full.names = TRUE)) source(f)
med <- Sys.getenv("RACAFE_MEDICIONES")
if (!nzchar(med)) stop("Defina RACAFE_MEDICIONES con la ruta del CSV de mediciones")
out <- Sys.getenv("RACAFE_SALIDA", "outputs/real")
dir.create(out, recursive = TRUE, showWarnings = FALSE)
m <- leer_mediciones(med); f <- filtrar_imposibles(m); m <- clasificar_lecturas(f$datos)
ep <- extraer_episodios(a_horario(m))
dias <- m |> dplyr::group_by(sede_codigo, logger) |>
  dplyr::summarise(dias_obs = as.numeric(difftime(max(ts), min(ts), units = "days")), .groups = "drop")
cat("Lecturas:", nrow(m), " imposibles descartados:", f$n_descartados, "\n")
cat(sprintf("%% alarma amplia: %.2f  | %% evento crítico: %.2f\n", 100*mean(m$alarma_amplia), 100*mean(m$evento_critico)))
cat("Episodios críticos:", nrow(ep), " bodegas:", nrow(dias), "\n")
print(summary(ep$duracion_h))
a <- resumen_alarmas(m); print(a)
readr::write_csv(a, file.path(out, "oe1_alarmas_por_sede.csv"))
readr::write_csv(duracion_eventos(ep), file.path(out, "oe1_duracion_por_bodega.csv"))
readr::write_csv(as.data.frame(ajustar_duracion(ep$duracion_h)), file.path(out, "oe1_ajuste_duracion.csv"))
