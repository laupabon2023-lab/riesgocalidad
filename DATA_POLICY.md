# Política de datos

- **Este repositorio es público y no contiene datos de Racafé.** No existe todavía
  autorización escrita de la contraparte para publicar mediciones, lotes ni rebajas.
- Todo lo versionado en `data/sintetico/` es **simulado** (scripts en `data-raw/`),
  con semilla fija. No reproduce ni se calibró contra cifras reales de Racafé.
- Las salidas de `outputs/sintetico/` y `reports/` se calculan solo sobre datos
  sintéticos y están rotuladas como tales.
- El análisis con datos reales se corre **en local** con `scripts/run_oe1_real.R` o
  `scripts/run_all.R` con variables de entorno; escribe en `outputs/real/`, que Git
  ignora. Resultados reales solo se publican con autorización escrita.
- Ninguna herramienta de IA en la nube recibe datos reales de Racafé.
