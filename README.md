# Riesgo por la ventana de actualización semanal — Racafé (Consultoría Estadística, USTA)

Modelo de riesgo colectivo (frecuencia–severidad) con Monte Carlo para cuantificar la
pérdida agregada anual por rebajas, y su VaR/CVaR 95 %, atribuible al tiempo entre la
medición horaria y la actualización semanal (lunes) del tablero; se compara contra
actualización diaria y en tiempo real.

> **Los datos de este repositorio son sintéticos.** Los números de `outputs/sintetico/` y
> `reports/` validan el código, no son hallazgos sobre Racafé. Ver `DATA_POLICY.md`.

Autores: Laura Pabón, Santiago García Roa. Lenguaje: R.

## Estructura
- `R/` funciones: clasificación, episodios, refresco, OE1, severidad, Monte Carlo, pipeline.
- `data-raw/` generadores de los datos sintéticos (semilla fija).
- `data/sintetico/` mediciones y lotes simulados. `data/real/` vacía (ignorada por Git).
- `scripts/run_all.R` pipeline completo; `scripts/run_oe1_real.R` OE1 solo en local.
- `tests/` pruebas `testthat`. `reports/informe_sintetico.html` informe reproducible.
- `docs/AVANCE.md` avance por objetivo, con criterio explícito.

## Cómo correr
```r
# Paquetes: dplyr, ggplot2, lubridate, readr, tidyr, data.table, purrr, MASS, testthat, rmarkdown
testthat::test_dir("tests/testthat")          # pruebas
source("scripts/run_all.R")                   # sintético -> outputs/sintetico/ (~4 min)
rmarkdown::render("reports/informe.Rmd")      # informe
```
Con datos reales (solo en local, nunca subir):
```sh
RACAFE_MEDICIONES=/ruta/mediciones.csv RACAFE_LOTES=/ruta/lotes.csv Rscript scripts/run_all.R
```
Salida en `outputs/real/` (ignorada por Git).

## Modo híbrido (solo local): mediciones reales + operación simulada
Racafé aún no entrega lotes, rebajas ni información operativa. Mientras tanto, estos tres
se **simulan** sobre las mediciones reales (`data-raw/simular_operacion.R`):
- *Operación:* tiempo de respuesta lognormal por sede (mediana 3–12 h) y demora ocasional de 48 h.
- *Lotes:* estancias de ~12 días por bodega, con peso, variedad y precio.
- *Rebajas:* curva no lineal y saturada de las horas sin corregir bajo esa operación, ruido
  y ~12 % de rebajas por otras causas no ambientales. A diferencia de `simular_lotes.R`,
  la rebaja **no** se genera con el mismo modelo que luego se ajusta.
```sh
RACAFE_MEDICIONES=/ruta/mediciones.csv Rscript scripts/run_hibrido.R   # salidas en outputs/real/ (ignorada)
```
Con datos reales se trabaja a nivel **sede**, excluyendo sensores exteriores (`R/operacion.R`),
porque los nombres de logger son inconsistentes y no hay mapa logger → bodega. Las cifras
resultantes combinan datos reales con supuestos simulados: **no son hallazgos sobre Racafé**.

## Supuestos del modelo
Evento = racha de horas críticas (GPP > 100, T > 28 °C o T − T. rocío ≤ 2 °C). Horas sin
corregir = mín(duración, espera hasta el próximo refresco + 4 h de respuesta). Rebaja =
mín(25 %, k·horas), k ajustado por mínimos cuadrados. Esquemas: semanal (lunes 08:00),
diaria (08:00), tiempo real (latencia 1 h). Sensibilidad en `oe3_sensibilidad.csv` y escenarios optimista/base/pesimista en `oe3_escenarios.csv` (carpeta `outputs/sintetico/`).

## Pendiente (requiere a Racafé)
1. Lotes con rebajas reales y mapa logger → bodega (OE2–OE4 con datos reales).
2. Contrastar la clasificación con la función del tablero de producción.
3. Autorización escrita para publicar datos; licencia por definir.
