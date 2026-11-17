# Table formatting.
esttab_a3 <- function(x) vapply(x, function(z) {
  a <- abs(z)
  if (a == floor(a)) return(sprintf("%.0f", z))
  if (a < 1) {
    decimals <- max(1, 3 - trunc(log10(a)))
    if (decimals > 9) return(sprintf("%.2e", z))
  } else {
    left <- trunc(log10(a) + 1)
    if (left > 9) return(sprintf("%.0e", z))
    decimals <- max(1, 4 - left)
  }
  sprintf(paste0("%.", decimals, "f"), z)
}, character(1))

# Round decimal ties away from zero, as in the paper-style display.
half_up <- function(x, digits) {
  scale <- 10^digits
  sign(x) * floor(abs(x) * scale + 0.5 + 1e-10) / scale
}
table_format <- function(x, outcome, statistic) {
  if (statistic == "joint_p") {
    if (x < 0.0001) return("<0.0001")
    digits <- 4
  } else digits <- if (startsWith(outcome, "any_")) 3 else 0
  sprintf(paste0("%.", digits, "f"), half_up(x, digits))
}

make_table <- function(audit, display, counts, N, G) {
  ys <- unique(audit$outcome)
  terms <- unique(audit$term[audit$statistic != "joint_p"])
  labels <- c("Free care (adjusted level)", "25% coinsurance", "Mixed coinsurance",
              "50% coinsurance", "Individual deductible", "95% coinsurance")
  counts <- counts[c(1, 2, 3, 4, 6, 5)]
  ans <- data.frame(Row = c(rbind(paste0(labels, " [N=", counts, "]"),
                                 rep("Clustered SE", 6))), check.names = FALSE)
  for (y in ys) {
    vals <- character()
    for (t in terms) {
      a <- audit[audit$outcome == y & audit$term == t, ]
      vals <- c(vals, a[[display]][a$statistic == "estimate"],
                paste0("(", a[[display]][a$statistic == "standard_error"], ")"))
    }
    ans[[y]] <- vals
  }
  p <- audit[audit$statistic == "joint_p", ]
  rbind(ans, c("Joint p: all plan effects = 0", p[[display]][match(ys, p$outcome)]),
        c("Person-year observations", rep(as.character(N), 6)),
        c("Family clusters (ifamily)", rep(as.character(G), 6)))
}

write_table_tex <- function(tab, path) {
  esc <- function(x) gsub("<", "$<$", gsub("%", "\\%", x, fixed = TRUE), fixed = TRUE)
  row_end <- paste0(" ", strrep("\\", 2))
  body <- apply(tab, 1, function(r) paste0(paste(esc(r), collapse = " & "), row_end))
  writeLines(c("\\documentclass[11pt]{article}",
    "\\usepackage[landscape,margin=0.7in]{geometry}", "\\usepackage{booktabs}",
    "\\begin{document}", "\\begin{center}",
    "{\\Large Table 2: Plans' Effects on Utilization}\\par\\medskip",
    "R replication of Aron-Dine, Einav and Finkelstein (2013)\\par\\bigskip",
    "\\begin{tabular}{lrrrrrr}\\toprule",
    " & \\multicolumn{2}{c}{Total spending} & \\multicolumn{2}{c}{Inpatient spending} & \\multicolumn{2}{c}{Outpatient spending} \\\\",
    " & Any (1) & Dollars (2) & Any (3) & Dollars (4) & Any (5) & Dollars (6) \\\\\\midrule",
    body, "\\bottomrule\\end{tabular}\\end{center}",
    "\\small All models are OLS; binary outcomes are linear probability models. Spending is in 2011 dollars.",
    "Site-by-start-month and calendar-year indicators are centered; SEs are clustered on ifamily.",
    "This display reconstructs esttab's a3 export followed by publication rounding.",
    "The two affected cells are SE 264.494994 to 264.5 to 265, and p 0.153863528 to 0.154 to 0.1540.",
    "The final publication step is inferred; the original intermediate CSV is unavailable.",
    "Full-precision estimates and a direct-rounding table accompany this display.",
    "\\end{document}"), path)
}

write_table_pdf <- function(paper, direct, path) {
  grDevices::pdf(path, width = 11.7, height = 8.3, family = "Helvetica",
                 title = "Table 2 - R replication", useDingbats = FALSE)
  on.exit(grDevices::dev.off())
  for (page in 1:2) {
    tab <- if (page == 1) paper else direct
    grid::grid.newpage()
    text <- function(label, x, y, size = 10, bold = FALSE, just = "center", col = "#172433")
      grid::grid.text(label, x = x, y = y, just = just,
        gp = grid::gpar(fontsize = size, fontface = if (bold) "bold" else "plain", col = col))
    line <- function(y, color = "#B8C6D3") grid::grid.lines(x = c(.05, .95), y = c(y, y), gp = grid::gpar(col = color))
    text("STAT 5200  /  REPLICATION", .05, .945, 9, TRUE, "left", "#386377")
    text("Table 2. Plans' Effects on Utilization", .05, .897, 21, TRUE, "left")
    text(if (page == 1) "Paper-style display: all 78 published entries reproduced" else
      "Direct rounding from full precision: two display differences retained",
      .05, .855, 11, FALSE, "left", "#526575")
    xs <- c(.05, seq(.43, .93, length.out = 6))
    text("Insurance plan / statistic", xs[1], .792, 10, TRUE, "left")
    for (j in 1:3) text(c("Total spending", "Inpatient spending", "Outpatient spending")[j],
                         mean(xs[(2*j):(2*j+1)]), .805, 10, TRUE)
    for (j in 1:6) text(paste0(if (j %% 2) "Any" else "2011 USD", " (", j, ")"), xs[j+1], .77, 9)
    line(.749, "#386377")
    yy <- seq(.723, .245, length.out = nrow(tab))
    for (i in seq_len(nrow(tab))) {
      is_se <- i <= 12 && i %% 2 == 0
      label <- if (is_se) "" else tab$Row[i]
      text(label, xs[1], yy[i], if (i > 12) 9 else 9.5, !is_se, "left")
      for (j in 1:6) text(tab[i, j+1], xs[j+1], yy[i], if (is_se) 9 else 10,
                          FALSE, "center", if (is_se) "#657382" else "#172433")
      if (i == 12) line(mean(yy[12:13]))
    }
    line(.221, "#386377")
    notes <- c(
      "OLS for all six outcomes; binary outcomes are linear probability models. Zero-spending observations remain in the sample.",
      "Controls: centered site x family start-month indicators and calendar-year indicators from fam_start_year. SEs: cluster(ifamily), CR1.",
      "Free care is the reference; its row is an adjusted level, while the other rows are differences from free care. Amounts are in 2011 USD.",
      if (page == 1) "Display reconstruction: esttab a3, then final rounding. SE: 264.494994 -> 264.5 -> 265; joint p: 0.153863528 -> 0.154 -> 0.1540."
      else "Direct rounding gives 264 for the inpatient 50% SE and 0.1539 for the inpatient joint p. Underlying estimates are identical on both pages.",
      "The final publication-rounding step is an evidence-based inference; no native Stata run or authors' intermediate CSV was available.",
      "Source: Aron-Dine, Einav and Finkelstein (2013), JEP 27(1), p. 204. DOI: 10.1257/jep.27.1.197. Data: 10.3886/E113919V1.")
    for (i in seq_along(notes)) text(notes[i], .05, .185 - (i-1)*.023, 8, FALSE, "left", "#526575")
    text(paste0(page, " / 2"), .95, .03, 8, FALSE, "right", "#526575")
  }
}
