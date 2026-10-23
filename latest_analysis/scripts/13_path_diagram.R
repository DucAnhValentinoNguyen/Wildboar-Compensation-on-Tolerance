## 13_path_diagram.R -- hand-built, readable path diagram of the headline
## structural results (seminr's auto-layout for a 17-construct/89-path model
## is illegible; DiagrammeR->PNG export needs a system librsvg not available
## here). Only the theoretically central paths are drawn; full coefficient
## tables (including all controls) are in output/tables/41_plssem_full_paths.csv.
suppressPackageStartupMessages(library(ggplot2))

root <- Sys.getenv("WB_ANALYSIS_ROOT", unset = getwd())  # = latest_analysis/
fig_dir <- file.path(root, "output/figures")
paths <- read.csv(file.path(root, "output/tables/41_plssem_full_paths.csv"))
names(paths) <- make.names(names(paths))
paths$path <- trimws(gsub("->", "->", paths$path))

get_path <- function(from, to) {
  row <- paths[grepl(paste0("^", from, "\\s*->\\s*", to, "$"), gsub("  ", " ", paths$path)), ]
  if (nrow(row) == 0) return(list(est = NA, p = NA))
  list(est = round(row$Original.Est.[1], 2), p = row$Bootstrap.P.Val[1])
}

nodes <- data.frame(
  name = c("CP_WB","CP_A","Site","CE0",
           "PE","CA","PS","TC","IC","IB",
           "Tol"),
  x    = c(0,0,0,0,
           1.4,1.4,1.4,1.4,1.4,1.4,
           2.8),
  y    = c(4.5,3.5,2.5,1.5,
           5,4,3,2,1,0,
           2.5),
  label= c("Conflict Exp.\n(Wild boar)","Conflict Exp.\n(All species)","Survey Site\n(Baoxing=1)",
           "Compensation\nParticipation","Prevention\nEffectiveness","Compensation\nAnticipation",
           "Policy\nSupport","Tangible\nCost","Intangible\nCost","Intangible\nBenefit","TOLERANCE"),
  stringsAsFactors = FALSE
)

edges_spec <- list(
  c("CP_WB","TC"), c("CP_WB","IC"), c("CP_WB","IB"),
  c("CP_A","CE0"), c("CP_A","IC"), c("CP_A","TC"),
  c("Site","CE0"), c("Site","PS"), c("Site","TC"), c("Site","IC"), c("Site","IB"),
  c("CE0","Tol"),
  c("PE","Tol"), c("CA","Tol"), c("PS","Tol"), c("TC","Tol"), c("IC","Tol"), c("IB","Tol")
)

edges <- do.call(rbind, lapply(edges_spec, function(e) {
  pe <- get_path(e[1], e[2])
  data.frame(from = e[1], to = e[2], est = pe$est, p = pe$p)
}))
edges <- merge(edges, nodes[,c("name","x","y")], by.x = "from", by.y = "name")
names(edges)[names(edges) %in% c("x","y")] <- c("x1","y1")
edges <- merge(edges, nodes[,c("name","x","y")], by.x = "to", by.y = "name")
names(edges)[names(edges) %in% c("x","y")] <- c("x2","y2")
edges$sig <- ifelse(edges$p < .05, "p < .05", "n.s.")
edges$lty <- ifelse(edges$p < .05, "solid", "dashed")

p <- ggplot() +
  geom_segment(data = edges, aes(x = x1, y = y1, xend = x2, yend = y2,
                                  color = sig, linewidth = abs(est)),
               arrow = arrow(length = unit(0.2, "cm"), type = "closed")) +
  geom_label(data = edges, aes(x = (x1+x2)/2, y = (y1+y2)/2, label = sprintf("%.2f", est)),
             size = 3, label.size = 0, fill = "white", alpha = .85) +
  geom_label(data = nodes, aes(x = x, y = y, label = label),
             size = 3.2, fontface = "bold", fill = "grey95") +
  scale_color_manual(values = c("p < .05" = "#2c6e9e", "n.s." = "grey70")) +
  scale_linewidth(range = c(0.3, 1.6), guide = "none") +
  labs(title = "Wildlife Tolerance Model -- headline structural paths (full sample, n = 625)",
       subtitle = "Standardised PLS-SEM path coefficients; dashed/grey = not significant at 5%. Controls (gender, age,\neducation, income, household assets, national-park residence) omitted for legibility -- see full path table.",
       color = NULL) +
  theme_void(base_size = 12) +
  theme(legend.position = "bottom", plot.title = element_text(face = "bold"),
        plot.margin = margin(10,10,10,10))

ggsave(file.path(fig_dir, "10_path_diagram_headline.png"), p, width = 12, height = 8, dpi = 160)
cat("Path diagram saved.\n")
