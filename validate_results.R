# Optional check: Rscript validate_results.R
args <- commandArgs(trailingOnly = FALSE)
script <- sub("^--file=", "", args[startsWith(args, "--file=")][1])
root <- dirname(normalizePath(script))
d <- foreign::read.dta(file.path(root, "data", "person_years.dta"), convert.factors = FALSE)
models <- readRDS(file.path(root, "results", "estimates_and_covariances.rds"))
d$plan_factor <- factor(d$rand_plan_group)
d$site_month <- interaction(d$site, d$fam_start_month, drop = TRUE)
d$calendar_year <- factor(d$fam_start_year)
checks <- list()
for (y in names(models)) {
  # Use ordinary factors and calculate the clustered covariance directly.
  fit <- lm(reformulate(c("plan_factor", "site_month", "calendar_year"), y), data = d)
  Z <- model.matrix(fit)
  N <- nrow(Z)
  K <- fit$rank
  G <- length(unique(d$ifamily))
  B <- chol2inv(chol(crossprod(Z)))
  S <- rowsum(Z * residuals(fit), d$ifamily, reorder = FALSE)
  V <- G / (G - 1) * (N - 1) / (N - K) * B %*% crossprod(S) %*% B
  # Recover the adjusted free-care level.
  a <- colMeans(Z)
  a[2:6] <- 0
  A <- rbind(a, diag(ncol(Z))[2:6, , drop = FALSE])
  b <- drop(A %*% coef(fit))
  v <- A %*% V %*% t(A)
  terms <- c("(Intercept)", paste0("rand_plan_group", 2:6))
  target <- models[[y]]
  F_stat <- drop(crossprod(b[2:6], solve(v[2:6, 2:6], b[2:6]))) / 5
  p <- pf(F_stat, 5, target$clusters - 1, lower.tail = FALSE)
  checks[[y]] <- data.frame(outcome = y,
    max_coefficient_difference = max(abs(b - target$coefficients[terms])),
    max_se_difference = max(abs(sqrt(diag(v)) - sqrt(diag(target$covariance))[terms])),
    joint_p_difference = abs(p - target$p))
}
checks <- do.call(rbind, checks)
stopifnot(all(checks$max_coefficient_difference < 1e-7),
          all(checks$max_se_difference < 1e-7), all(checks$joint_p_difference < 1e-10))
write.csv(checks, file.path(root, "results", "independent_validation.csv"), row.names = FALSE)
capture.output(sessionInfo(), file = file.path(root, "results", "validation_sessionInfo.txt"))
print(checks, digits = 6)
cat("PASS: direct covariance and alternative factor coding validation for all 36 reported coefficients and SEs and all 6 joint p-values.\n")
