# Modelo de riesgo colectivo: pérdida anual = suma de severidades de N eventos.
#   N ~ Binomial Negativa (sobredispersión) o Poisson, por bodega
#   cada evento: (inicio, duración) re‑muestreado de los eventos observados
#   severidad = [lote presente] * valor_lote * pct_rebaja(horas sin corregir)
# Números aleatorios comunes: los mismos eventos y lotes se evalúan en todos
# los esquemas, así la diferencia entre esquemas es causal y no ruido.
suppressPackageStartupMessages({ library(dplyr) })

simular_perdida_anual <- function(episodios, lotes, ocup, freq_anual, size_nb,
                                  modelo, esquemas_eval = esquemas,
                                  n_sim = sim$n_sim, semilla = sim$semilla,
                                  respuesta = respuesta_h) {
  set.seed(semilla)
  valores <- lotes$peso_kg * lotes$precio_base_kg
  pares <- freq_anual |> left_join(ocup |> select(sede_codigo, logger = bodega, ocupacion),
                                   by = c("sede_codigo", "logger"))
  pares$ocupacion[is.na(pares$ocupacion)] <- mean(ocup$ocupacion)
  tot <- matrix(0, n_sim, length(esquemas_eval), dimnames = list(NULL, names(esquemas_eval)))
  for (i in seq_len(nrow(pares))) {
    b <- pares[i, ]
    ep_b <- episodios[episodios$sede_codigo == b$sede_codigo & episodios$logger == b$logger, ]
    if (nrow(ep_b) == 0 || b$mu <= 0) next
    N <- if (is.finite(size_nb)) rnbinom(n_sim, size = size_nb * b$mu / mean(pares$mu), mu = b$mu) else rpois(n_sim, b$mu)
    n_tot <- sum(N); if (n_tot == 0) next
    idx <- sample.int(nrow(ep_b), n_tot, replace = TRUE)
    presente <- runif(n_tot) < b$ocupacion
    v <- sample(valores, n_tot, replace = TRUE)
    sim_id <- rep.int(seq_len(n_sim), N)
    for (e in names(esquemas_eval)) {
      u <- horas_sin_corregir(ep_b$inicio[idx], ep_b$duracion_h[idx], esquemas_eval[[e]], respuesta)
      perdida <- presente * v * pct_rebaja(u, modelo)
      s <- rowsum(perdida, sim_id)
      acum <- numeric(n_sim); acum[as.integer(rownames(s))] <- s[, 1]
      tot[, e] <- tot[, e] + acum
    }
  }
  tot
}

var_cvar <- function(x, nivel = sim$nivel) {
  v <- unname(quantile(x, nivel))
  c(media = mean(x), VaR = v, CVaR = mean(x[x >= v]))
}

resumen_riesgo <- function(tot, nivel = sim$nivel, B = 200) {
  r <- t(apply(tot, 2, var_cvar, nivel = nivel))
  out <- as.data.frame(r); out$esquema <- rownames(r); rownames(out) <- NULL
  base <- out$CVaR[out$esquema == "semanal"]
  out$reduccion_CVaR_pct <- 100 * (1 - out$CVaR / base)
  out$reduccion_VaR_pct  <- 100 * (1 - out$VaR / out$VaR[out$esquema == "semanal"])
  # IC bootstrap (percentil) del CVaR por esquema
  ic <- sapply(colnames(tot), function(e) {
    bs <- replicate(B, var_cvar(sample(tot[, e], replace = TRUE), nivel)["CVaR"])
    quantile(bs, c(0.025, 0.975))
  })
  out$CVaR_ic_inf <- ic[1, out$esquema]; out$CVaR_ic_sup <- ic[2, out$esquema]
  out[, c("esquema", "media", "VaR", "CVaR", "CVaR_ic_inf", "CVaR_ic_sup",
          "reduccion_VaR_pct", "reduccion_CVaR_pct")]
}
