# Configuración central del proyecto. Todo supuesto del modelo vive aquí,
# visible y editable, para que ninguna cifra dependa de un valor escondido.

# Umbrales de negocio del sistema de monitoreo (tabla de la sección 1.2 del
# anteproyecto). NOTA: son los umbrales publicados en el anteproyecto; la
# lógica exacta del tablero de producción debe contrastarse con esta (ver
# README, "Validación pendiente").
umbrales <- list(
  gpp_seguro        = c(55, 70),   # zona segura (normal)
  gpp_critico       = 100,         # > 100: saturado
  hr_seguro         = c(55, 70),   # % HR óptimo
  hr_seco           = 45,          # < 45: aire seco
  temp_alta         = 28,          # > 28 °C: alto
  temp_baja         = 14,          # < 14 °C: bajo
  # Condensación: temperatura ambiente cerca del punto de rocío.
  margen_condensacion_c = 2        # (T - Td) <= 2 °C => riesgo de condensación
)

# Qué cuenta como "evento" para el modelo frecuencia-severidad.
# "critico" = GPP saturado (> 100) o temperatura alta o riesgo de condensación.
# Con la definición amplia (cualquier lectura fuera de la zona segura) ~94 %
# de las horas están "en alarma" y los episodios se funden en uno solo, por
# lo que no sirven para contar eventos (ver docs/AVANCE.md, hallazgo OE1).
definicion_evento <- "critico"

# Esquemas de actualización de datos (OE2/OE3).
# hora_carga: hora local a la que el dato queda visible en el tablero.
esquemas <- list(
  semanal     = list(tipo = "semanal", dia = "lunes", hora_carga = 8),
  diaria      = list(tipo = "diaria",  hora_carga = 8),
  tiempo_real = list(tipo = "tiempo_real", latencia_h = 1)
)

# Horas entre que el evento es visible y se corrige (supuesto, sensibilidad
# en OE3).
respuesta_h <- 4

# Parámetros del modelo de severidad y de la simulación.
severidad <- list(
  tope_pct = 0.25,   # rebaja máxima observada/supuesta (25 %)
  beta     = 1       # exponente de la severidad por horas sin corregir
)
sim <- list(n_sim = 10000, semilla = 2026, nivel = 0.95)
