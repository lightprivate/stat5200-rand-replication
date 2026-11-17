# Compare with the published table after estimation.
reference <- read.csv(file.path(root, "reference", "published_table2.csv"),
                      colClasses = "character", check.names = FALSE)
audit <- reference
audit$full_precision <- NA_real_
audit$esttab_a3 <- audit$direct_display <- audit$paper_style_display <- NA_character_
for (i in seq_len(nrow(audit))) {
  y <- audit$outcome[i]
  stat <- audit$statistic[i]
  if (stat == "joint_p") {
    value <- models[[y]]$p
  } else {
    r <- raw[raw$outcome == y & raw$term == audit$term[i], ]
    value <- r[[stat]]
  }
  intermediate <- esttab_a3(value)
  audit$full_precision[i] <- value
  audit$esttab_a3[i] <- intermediate
  audit$direct_display[i] <- table_format(value, y, stat)
  audit$paper_style_display[i] <- table_format(as.numeric(intermediate), y, stat)
}
audit$direct_match <- audit$direct_display == audit$published_display
audit$paper_style_match <- audit$paper_style_display == audit$published_display
stopifnot(nrow(audit) == 78L, all(audit$paper_style_match),
          sum(audit$direct_match) == 76L)
write.csv(audit, file.path(out, "comparison_78_cells.csv"), row.names = FALSE)
write.csv(audit[!audit$direct_match, ], file.path(out, "rounding_diagnostics.csv"),
          row.names = FALSE)

# Export the tables and run information.
table_paper <- make_table(audit, "paper_style_display", expected_counts, N, G)
table_direct <- make_table(audit, "direct_display", expected_counts, N, G)
write.csv(table_paper, file.path(out, "table2_paper_style.csv"), row.names = FALSE)
write.csv(table_direct, file.path(out, "table2_direct_rounding.csv"), row.names = FALSE)
write_table_tex(table_paper, file.path(out, "table2.tex"))
write_table_pdf(table_paper, table_direct, file.path(out, "Table2_replication.pdf"))
capture.output(sessionInfo(), file = file.path(out, "sessionInfo.txt"))
checks <- c("PASS: N=20,203; individuals=5,915; family clusters=3,209; rank=41.",
            "PASS: no duplicate person-year; six plan sample counts match.",
            "PASS: binary outcome indicators agree with source spending variables.",
            "PASS: all 78 published cells match after the documented display reconstruction.",
            "PASS: 76/78 cells match after direct rounding from full precision.",
            paste("Input MD5:", unname(tools::md5sum(input))),
            "No native Stata execution was performed.",
            "esttab a3 is verified from source/documentation; the final publication-rounding step is inferred.")
writeLines(checks, file.path(out, "validation.txt"))
cat(paste(checks, collapse = "\n"), "\nResults:", out, "\n")
