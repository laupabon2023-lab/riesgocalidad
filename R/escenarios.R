# Escenarios de severidad (OE3). Cada escenario cambia SUPUESTOS del modelo de
# severidad y de respuesta; no son datos. Se reporta el rango, no un valor único.
#   mult_k : multiplica el k ajustado (rebaja por hora más o menos agresiva)
#   beta   : forma (1 = lineal; el efecto de beta > 1 se ve en oe3_sensibilidad.csv)
#   tope   : rebaja máxima por lote
#   mult_resp : multiplica el tiempo de respuesta base (horas entre que el dato
#               es visible y se corrige)
escenarios_severidad <- list(
  optimista = list(mult_k = 0.5, beta = 1.0, tope = 0.15, mult_resp = 0.25),
  base      = list(mult_k = 1.0, beta = 1.0, tope = 0.25, mult_resp = 1),
  pesimista = list(mult_k = 1.5, beta = 1.0, tope = 0.25, mult_resp = 3)
)

correr_escenarios <- function(lotes_exp, episodios, lotes, ocup, freq, size_nb,
                              n_sim = 3000, semilla = sim$semilla, resp_base = respuesta_h) {
  out <- lapply(names(escenarios_severidad), function(nm) {
    p <- escenarios_severidad[[nm]]
    mod <- ajustar_severidad(lotes_exp, beta = p$beta, tope = p$tope)
    mod$k <- mod$k * p$mult_k
    tot <- simular_perdida_anual(episodios, lotes, ocup, freq, size_nb, mod,
                                 n_sim = n_sim, semilla = semilla, respuesta = resp_base * p$mult_resp)
    r <- resumen_riesgo(tot, B = 50)
    cbind(escenario = nm, mult_k = p$mult_k, beta = p$beta, tope = p$tope,
          respuesta_h = resp_base * p$mult_resp, r)
  })
  bind_rows(out)
}
