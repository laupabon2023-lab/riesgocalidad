# Avance frente a los objetivos del primer corte

Criterio explícito (cada objetivo = 4 componentes de 25 %):
**(1)** diseño y código, **(2)** pruebas automáticas, **(3)** ejecución completa sobre
datos sintéticos, **(4)** ejecución con datos reales de Racafé.

| Objetivo | (1) Código | (2) Pruebas | (3) Sintético | (4) Datos reales | Avance |
|---|---|---|---|---|---|
| OE1 Frecuencia y duración de alarmas por trilladora y bodega; humedad vs condensación | ✅ | ✅ | ✅ | 🟡 parcial: corrió en local por trilladora; falta el mapa logger→bodega | **87,5 %** |
| OE2 Cruce lote–bodega–fecha–rebaja, severidad y VaR/CVaR 95 % (esquema semanal) | ✅ | ✅ | ✅ | ❌ faltan lotes y rebajas reales | **75 %** |
| OE3 Comparación con actualización diaria y en tiempo real | ✅ (+ sensibilidad) | ✅ | ✅ | ❌ depende de OE2 real | **75 %** |
| OE4 Formato reproducible, integrable al tablero o módulo independiente | ✅ (módulo + `run_all`) | ✅ | ✅ (informe) | ❌ falta integrar al tablero | **75 %** |
| **Promedio simple** | | | | | **≈ 78 %** |

**Lectura honesta.** El método está completo, probado y reproducible; lo que falta es lo
que solo Racafé puede dar: los lotes con sus rebajas de precio (sin ellos OE2 y OE3 no
tienen resultado real) y el mapa de dataloggers a bodegas. El 78 % mide avance de
implementación y verificación, no resultados sobre Racafé: esos están en 0 % para OE2–OE4.

## Hallazgos de OE1 que cambian el modelo

1. Con los umbrales de la tabla, ~94 % de las horas reales caen en "alarma amplia"; los
   episodios se funden en uno solo y no sirven para contar eventos. El modelo usa
   **eventos críticos** (GPP > 100, temperatura > 28 °C o riesgo de condensación),
   alrededor de un 28 % de las lecturas en el conjunto local.
2. El conjunto real trae ~326 dataloggers distintos, no un número razonable de bodegas:
   hace falta una tabla logger → bodega para el análisis por bodega y el cruce con lotes.
3. La clasificación reimplementa los umbrales publicados en el anteproyecto; da 93,69 %
   en el conjunto local (filas distintas de las 155.028 del anteproyecto, que dan 93,76 %).
   **Pendiente:** contrastarla fila a fila con la función del tablero de producción.

## Validación con datos sintéticos

- Recuperación de parámetros: el ajuste devuelve k = 5,02·10⁻⁴ frente al valor
  verdadero 5·10⁻⁴ (R² = 0,960).
- Consistencia: la media anual simulada (1.248 M COP) coincide en ~6 % con la rebaja
  observada anualizada de los lotes sintéticos (1.332 M COP).
- Los esquemas se ordenan como se espera (semanal ≥ diaria ≥ tiempo real) en todas las
  combinaciones de supuestos probadas.
Estas pruebas validan que el código hace lo que dice; **no** validan los supuestos del
modelo con datos reales.

## Calibración de la simulación y escenarios

- La simulación de mediciones se calibró para que la proporción de lecturas críticas
  (29 %) y en alarma amplia (84 %) fuera del orden de lo observado en local (28 % y
  94 %). Solo se usaron esas dos proporciones agregadas; no se copió ningún dato
  individual. Incluye estacionalidad (lluvias abril–junio) y heterogeneidad entre sedes.
- `oe3_escenarios.csv` reporta tres escenarios de severidad (optimista, base, pesimista).
  CVaR 95 % semanal: 649, 1.315 y 2.041 M COP; la reducción pasando a tiempo real va de
  30 % (pesimista) a 83 % (optimista). Son supuestos, no estimaciones sobre Racafé.

## Modo híbrido y límites conocidos
- Se agregó `scripts/run_hibrido.R`: mediciones reales + lotes, rebajas y operación simulados
  con un mecanismo distinto del modelo ajustado (dosis-respuesta no lineal, otras causas,
  respuesta variable). El ajuste lineal ya no recupera el parámetro exacto (R² ≈ 0,8 en
  la corrida local), que es más realista.
- A nivel sede, un solo flujo de lotes por sede **subestima** la pérdida frente a varias
  bodegas simultáneas. Se corrige al contar con el mapa logger → bodega.
- En la corrida local, dos sedes (RH y RS) aparecen en estado crítico >90 % del tiempo,
  casi todo por temperatura alta; probablemente sensores en zona de secado o mal ubicados.
  Hay que confirmarlo con Racafé antes de interpretar esos eventos como riesgo de bodega.
