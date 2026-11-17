# Paper-specific inference beyond the reviewed DataCamp exercises.
table2_inference <- function(fit, family) {
  b <- coef(fit)
  X <- model.matrix(fit)
  V <- vcovCL(fit, cluster = family, type = "HC1", cadjust = TRUE)
  N <- nrow(X)
  G <- length(unique(family))
  plans <- match(paste0("plan", 2:6), names(b))
  stopifnot(fit$rank == 41, G == 3209, !anyNA(b), !anyNA(plans))

  # Free care at the sample-average control values, plus five plan effects.
  average <- colMeans(X)
  average[plans] <- 0
  A <- rbind(average, diag(length(b))[plans, , drop = FALSE])
  estimates <- drop(A %*% b)
  covariance <- A %*% V %*% t(A)
  terms <- c("(Intercept)", paste0("rand_plan_group", 2:6))
  names(estimates) <- terms
  dimnames(covariance) <- list(terms, terms)

  # Cluster-robust joint F test for the five plan effects.
  effects <- b[plans]
  F_stat <- drop(t(effects) %*% solve(V[plans, plans], effects)) / 5
  p <- pf(F_stat, df1 = 5, df2 = G - 1, lower.tail = FALSE)
  list(coefficients = estimates, covariance = covariance,
       N = N, rank = fit$rank, clusters = G, F = F_stat, p = p)
}
