#!/usr/bin/env Rscript
# MODO HÍBRIDO (solo local): mediciones REALES + lotes, rebajas y operación SIMULADOS.
# Las salidas quedan en outputs/real/ y data/real/, ignoradas por Git. No publicar.
#   RACAFE_MEDICIONES=/ruta/mediciones.csv Rscript scripts/run_hibrido.R
for (f in list.files("R", full.names = TRUE)) source(f)
med <- Sys.getenv("RACAFE_MEDICIONES", "")
if (!nzchar(med)) stop("Defina RACAFE_MEDICIONES (ruta al CSV de mediciones reales).")
status <- system2("Rscript", c("data-raw/simular_operacion.R", shQuote(med), "sede", "data/real"))
if (status != 0) stop("Falló la simulación de lotes y operación")
res <- ejecutar_pipeline(med, "data/real/lotes_simulados.csv", "outputs/real",
                         etiqueta = "REAL-MEDICIONES+OPERACION-SIMULADA",
                         nivel = "sede", ruta_operacion = "data/real/operacion_simulada.csv")
print(res$riesgo)
