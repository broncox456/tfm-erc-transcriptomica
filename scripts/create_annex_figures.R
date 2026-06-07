library(pheatmap)

message("Buscando matriz de expresión procesada...")

possible_files <- c(
  "data/processed/exprs_genes_norm.rds",
  "data/processed/exprs_probes_norm.rds"
)

expr_file <- possible_files[file.exists(possible_files)][1]

if (is.na(expr_file)) {
  stop("No se encontró matriz RDS en data/processed/. Revisa si existe exprs_genes_norm.rds o exprs_probes_norm.rds")
}

expr <- readRDS(expr_file)

if (!is.matrix(expr)) {
  expr <- as.matrix(expr)
}

message("Matriz cargada desde: ", expr_file)

vars <- apply(expr, 1, var, na.rm = TRUE)
top100 <- names(sort(vars, decreasing = TRUE))[1:100]

mat_top100 <- expr[top100, , drop = FALSE]
mat_top100_z <- t(scale(t(mat_top100)))

png(
  filename = "results/annexes/figures/Figura_A2_heatmap_extendido_top100_genes.png",
  width = 1800,
  height = 2200,
  res = 220
)

pheatmap(
  mat_top100_z,
  show_rownames = FALSE,
  show_colnames = FALSE,
  clustering_distance_rows = "euclidean",
  clustering_distance_cols = "euclidean",
  clustering_method = "complete",
  main = "Extended heatmap of the top 100 most variable genes"
)

dev.off()

message("Figura A2 creada correctamente.")