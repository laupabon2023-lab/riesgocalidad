#!/usr/bin/env Rscript
# Uso:
#   Rscript scripts/run_all.R                      # datos SINTÉTICOS (por defecto)
#   RACAFE_MEDICIONES=/ruta/mediciones.csv RACAFE_LOTES=/ruta/lotes.csv \
#     Rscript scripts/run_all.R                    # datos reales, SOLO en local
# Con datos reales las salidas van a outputs/real/ (ignorada por git).
for (f in list.files("R", full.names = TRUE)) source(f)
med <- Sys.getenv("RACAFE_MEDICIONES", "")
lot <- Sys.getenv("RACAFE_LOTES", "")
if (nzchar(med)) {
  if (!nzchar(lot)) lot <- "data/sintetico/lotes_sinteticos.csv"
  message("MODO LOCAL con datos reales. No publicar outputs/real/")
  etiqueta <- if (grepl("sintetico", lot)) "REAL-MEDICIONES+LOTES-SINTETICOS" else "REAL"
  res <- ejecutar_pipeline(med, lot, "outputs/real", etiqueta = etiqueta)
} else {
  res <- ejecutar_pipeline("data/sintetico/mediciones_sinteticas.csv",
                           "data/sintetico/lotes_sinteticos.csv",
                           "outputs/sintetico", etiqueta = "SINTETICO")
}
print(res$riesgo)
