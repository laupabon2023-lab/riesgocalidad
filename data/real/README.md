# data/real/ (vacía a propósito)

Aquí se coloca, **solo en el computador de quien corre el análisis**, el CSV de
mediciones reales. Git lo ignora (ver `.gitignore`). No subir nada de esta carpeta.

Esquema esperado de `mediciones.csv`: `sede_codigo`, `logger` (o `logging_name`),
`fecha_hora`, `temperatura`, `humedad_relativa`, `punto_rocio`, `gpp`.

Esquema esperado de `lotes.csv` (cuando Racafé autorice y entregue los datos):
`lote_id`, `sede_codigo`, `bodega`, `fecha_entrada`, `fecha_salida`, `peso_kg`,
`precio_base_kg`, `pct_rebaja`.
