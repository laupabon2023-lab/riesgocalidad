# Genera mediciones horarias SINTÉTICAS (sin relación con datos de Racafé).
# Física real: la humedad absoluta (GPP, granos de agua por libra de aire
# seco) y el punto de rocío se calculan a partir de T y HR con la fórmula de
# Magnus y la relación psicrométrica, así que las 4 variables son coherentes.
set.seed(20260101)
sedes <- c("RA", "RAA", "RB", "RH", "RM", "RP", "RS", "RY")
n_bod <- 3
horas <- seq(as.POSIXct("2026-02-01 00:00:00", tz = "UTC"),
             as.POSIXct("2026-09-20 23:00:00", tz = "UTC"), by = "hour")
n <- length(horas)
psat <- function(T) 0.61094 * exp(17.625 * T / (T + 243.04))          # kPa (Magnus)
rocio <- function(T, HR) { pv <- HR / 100 * psat(T); 243.04 * log(pv / 0.61094) / (17.625 - log(pv / 0.61094)) }
gpp   <- function(T, HR) { pv <- HR / 100 * psat(T); 7000 * 0.62198 * pv / (101.325 - pv) }
ar1 <- function(n, phi, sd) { x <- numeric(n); e <- rnorm(n, 0, sd); for (i in 2:n) x[i] <- phi * x[i - 1] + e[i]; x }

filas <- list()
for (s in sedes) {
  off_T  <- rnorm(1, 0, 1.2); off_HR <- rnorm(1, 0, 4)
  # componente lenta común a la sede (racha de tiempo húmedo/seco, escala de días)
  lenta <- ar1(n, 0.995, 0.9)
  for (b in seq_len(n_bod)) {
    h <- as.numeric(format(horas, "%H"))
    T  <- 23.5 + off_T + rnorm(1, 0, 0.5) + 3 * sin(2 * pi * (h - 9) / 24) + ar1(n, 0.97, 0.35) + 0.15 * lenta
    HR <- 63 + off_HR + rnorm(1, 0, 1.5) - 4 * sin(2 * pi * (h - 9) / 24) + 0.5 * lenta + ar1(n, 0.95, 0.7)
    HR <- pmin(94, pmax(35, HR))
    filas[[length(filas) + 1]] <- data.frame(
      sede_codigo = s, logger = sprintf("%s-B%d", s, b),
      fecha_hora = format(horas, "%Y-%m-%d %H:%M:%S"),
      temperatura = round(T, 1), humedad_relativa = round(HR, 1),
      punto_rocio = round(rocio(T, HR), 1), gpp = round(gpp(T, HR), 1))
  }
}
d <- do.call(rbind, filas)
write.csv(d, "data/sintetico/mediciones_sinteticas.csv", row.names = FALSE)
cat("filas:", nrow(d), "\n")
