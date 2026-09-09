# Module 07: Integrated assessment-readiness review
#
# Purpose: synthesize Modules 02-06 into an explicit pre-assessment evidence
# framework. No stock-assessment model is fitted here.

library(ggplot2)

# Scores are ordinal diagnostics, not statistical weights:
# support/comparability: 1 poor -> 4 strong
# observation/provenance risk: 1 low -> 4 critical
readiness <- data.frame(
  domain = c(
    "Catch and effort", "Commercial CPUE", "Sampling coverage",
    "Length frequencies", "LFD temporal comparability", "LFD spatial comparability",
    "Age composition", "Age-length keys", "Reader agreement",
    "Weight-length", "Maturity / L50", "Growth parameters",
    "Natural mortality", "Spawning phenology"
  ),
  module = c(2,2,2,3,4,4,5,5,5,6,6,6,6,6),
  support = c(4,3,3,4,3,3,3,2,3,4,3,2,2,4),
  comparability = c(3,2,2,4,2,3,3,2,3,4,3,2,2,4),
  observation_risk = c(2,3,3,2,3,2,2,3,3,1,2,2,2,1),
  provenance_risk = c(1,2,1,1,1,1,1,2,1,1,2,4,4,1),
  key_issue = c(
    "unit/coding problems are resolvable but protocol changes must remain documented",
    "reported and recalculated CPUE conflict in some records; catchability may change",
    "uneven area-year sampling and missing strata",
    "strong sample size but heaping, selective gears and incomplete measurement scope occur",
    "pooled trends are sensitive to changing area/gear/source composition",
    "persistent strata are available, but not all areas/gears contribute equally through time",
    "reasonable support, with sparse old-age observations",
    "some length bins and strata have weak support; historical transferability is imperfect",
    "older ages show more disagreement and recent reader drift is simulated",
    "well supported when sex/source are retained",
    "source and period differences require sensitivity treatment",
    "candidate values differ in stock, sex, period and method provenance",
    "candidate M values are method-dependent and should be treated as a sensitivity range",
    "seasonal pattern is coherent across areas and sources"
  ),
  stringsAsFactors = FALSE
)

classify_readiness <- function(support, comparability, observation_risk, provenance_risk) {
  if (observation_risk >= 4 || provenance_risk >= 4 || support <= 1 || comparability <= 1)
    return("unresolved / not recommended")
  if (observation_risk >= 3 || provenance_risk >= 3 || support == 2 || comparability == 2)
    return("usable with sensitivity")
  if (support >= 3 && comparability >= 3 && observation_risk <= 2 && provenance_risk <= 2)
    return("supported")
  "usable with caveats"
}

readiness$status <- mapply(
  classify_readiness,
  readiness$support, readiness$comparability,
  readiness$observation_risk, readiness$provenance_risk
)
status_levels <- c("supported", "usable with caveats", "usable with sensitivity", "unresolved / not recommended")
readiness$status <- factor(readiness$status, levels = status_levels)

# Triage only: higher values mean more scientific follow-up is warranted.
readiness$priority_score <- (5 - readiness$support) + (5 - readiness$comparability) +
  readiness$observation_risk + readiness$provenance_risk
readiness$priority <- cut(
  readiness$priority_score,
  breaks = c(-Inf, 8, 11, Inf),
  labels = c("routine", "important", "high")
)

status_ok <- function(x) as.character(x) %in%
  c("supported", "usable with caveats", "usable with sensitivity")

# Machine-readable evidence-family IDs deliberately match the scenario-matrix
# column names. Human-readable domain labels remain separate.
input_gates <- data.frame(
  evidence_family = c(
    "catch_history", "abundance_index", "length_composition",
    "age_composition", "growth_maturity", "natural_mortality"
  ),
  representative_domain = c(
    "Catch and effort", "Commercial CPUE", "Length frequencies",
    "Age composition", "Maturity / L50", "Natural mortality"
  ),
  stringsAsFactors = FALSE
)
input_gates$status <- readiness$status[match(input_gates$representative_domain, readiness$domain)]
input_gates$gate_open <- vapply(input_gates$status, status_ok, logical(1))

# Analysis scenarios describe evidence requirements only; they are not model recommendations.
scenario_matrix <- data.frame(
  scenario = c(
    "Descriptive / indicator synthesis",
    "Length-based exploratory analysis",
    "Index-based trend analysis",
    "Age-structured exploratory analysis",
    "Integrated assessment candidate"
  ),
  catch_history = c(TRUE, FALSE, FALSE, TRUE, TRUE),
  abundance_index = c(FALSE, FALSE, TRUE, TRUE, TRUE),
  length_composition = c(TRUE, TRUE, FALSE, TRUE, TRUE),
  age_composition = c(FALSE, FALSE, FALSE, TRUE, TRUE),
  growth_maturity = c(FALSE, TRUE, FALSE, TRUE, TRUE),
  natural_mortality = c(FALSE, TRUE, FALSE, TRUE, TRUE),
  stringsAsFactors = FALSE
)

family_gate <- setNames(input_gates$gate_open, input_gates$evidence_family)
scenario_matrix$all_required_gates_open <- apply(
  scenario_matrix[, -1], 1,
  function(req) {
    needed <- names(req)[as.logical(req)]
    if (!length(needed)) return(TRUE)
    if (any(!needed %in% names(family_gate))) {
      stop(
        "Scenario contains an evidence family not defined in input_gates: ",
        paste(setdiff(needed, names(family_gate)), collapse = ", ")
      )
    }
    all(family_gate[needed])
  }
)

sensitivity_register <- data.frame(
  issue = c(
    "CPUE observation process", "sampling-design drift in pooled LFDs",
    "historical ALK transferability", "reader drift at older ages",
    "maturity source/period differences", "growth parameter provenance",
    "natural mortality"
  ),
  baseline_action = c(
    "recalculate from verified catch/effort and retain fleet/area structure",
    "use persistent-stratum or standardized comparisons alongside pooled summaries",
    "prefer contemporary/stratified ALKs where support allows",
    "exclude or sensitivity-test suspect reader-period combinations",
    "retain source/sex/period structure; avoid blind pooling",
    "prioritize target-stock contemporary estimates",
    "carry a plausible range rather than a single fixed value"
  ),
  sensitivity = c(
    "alternative CPUE definitions / exclude inconsistent records",
    "pooled versus fixed-design standardized LFD",
    "global versus area/source ALKs",
    "all reads versus stable-reader subset",
    "commercial versus survey maturity ogives",
    "alternative compatible growth parameter sets",
    "multiple M values and/or age-specific M scenarios"
  ),
  priority = c("high", "high", "important", "high", "important", "high", "high"),
  stringsAsFactors = FALSE
)

status_summary <- as.data.frame(table(readiness$status), stringsAsFactors = FALSE)
names(status_summary) <- c("status", "n_domains")

p_status <- ggplot(readiness, aes(x = reorder(domain, priority_score), y = priority_score, fill = status)) +
  geom_col() + coord_flip() +
  labs(x = NULL, y = "Follow-up priority score", fill = "Readiness",
       title = "Integrated assessment-readiness register",
       subtitle = "Higher scores indicate greater need for resolution or sensitivity treatment") +
  theme_minimal(base_size = 11)

risk_long <- rbind(
  data.frame(domain = readiness$domain, dimension = "Support", value = readiness$support),
  data.frame(domain = readiness$domain, dimension = "Comparability", value = readiness$comparability),
  data.frame(domain = readiness$domain, dimension = "Observation risk", value = readiness$observation_risk),
  data.frame(domain = readiness$domain, dimension = "Provenance risk", value = readiness$provenance_risk)
)
p_matrix <- ggplot(risk_long, aes(x = dimension, y = domain, fill = value)) +
  geom_tile() + geom_text(aes(label = value), size = 3) +
  scale_fill_gradient(low = "white", high = "grey30", limits = c(1, 4)) +
  labs(x = NULL, y = NULL, fill = "Ordinal score",
       title = "Evidence dimensions behind the readiness classification") +
  theme_minimal(base_size = 10) + theme(panel.grid = element_blank())

blockers <- readiness[as.character(readiness$status) == "unresolved / not recommended", ]
assessment_readiness_statement <- if (nrow(blockers) > 0) {
  paste0(
    "The evidence base is NOT yet ready for unconstrained assessment-model fitting. ",
    "Unresolved domains: ", paste(blockers$domain, collapse = "; "), "."
  )
} else {
  "No critical evidence blockers remain, but model-specific requirements still need evaluation."
}

stopifnot(
  nrow(readiness) >= 12,
  any(as.character(readiness$status) == "supported"),
  any(as.character(readiness$status) == "usable with sensitivity"),
  any(as.character(readiness$status) == "unresolved / not recommended"),
  !anyNA(scenario_matrix$all_required_gates_open),
  any(!scenario_matrix$all_required_gates_open)
)

print(readiness[, c("domain", "status", "priority", "key_issue")])
print(input_gates)
print(scenario_matrix)
print(sensitivity_register)
cat("\n", assessment_readiness_statement, "\n", sep = "")
