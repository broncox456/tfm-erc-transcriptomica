# ============================================================
# TFM_ERC_transcriptomica
# Script: R/04_qc.R
# Propósito:
#   - QC básico: boxplot, densidades
#   - Exploratorio: PCA (genes normalizados)
#   - Guardar figuras en results/qc y results/exploratory
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(data.table)
  library(stringr)
})

stop_pipeline <- function(msg) stop(glue('❌ QC ERROR: {msg}'), call. = FALSE)

PATHS  <- yaml::read_yaml('config/paths.yml')

dir_create(PATHS$results$qc, recurse = TRUE)
dir_create(PATHS$results$exploratory, recurse = TRUE)

# 1) Cargar matrices procesadas
expr_probes <- readRDS(file.path(PATHS$data$processed, 'exprs_probes_norm.rds'))
expr_genes  <- readRDS(file.path(PATHS$data$processed, 'exprs_genes_norm.rds'))
ss <- fread(file.path(PATHS$data$processed, 'sample_sheet_aligned.tsv'))

if (!all(c('sample_id','group') %in% names(ss))) stop_pipeline('sample_sheet_aligned.tsv debe tener sample_id y group')

# Asegurar orden
ss <- ss[match(colnames(expr_probes), ss$sample_id)]
stopifnot(all(ss$sample_id == colnames(expr_probes)))

# 2) Boxplot (probes)
png(file.path(PATHS$results$qc, 'boxplot_probes_norm.png'), width=1400, height=800, res=140)
par(mar=c(8,4,2,1))
boxplot(expr_probes, outline=FALSE, las=2, cex.axis=0.6, main='Boxplot (probes) - Normalizado', ylab='Expresión (log2)')
dev.off()

# 3) Densidades (probes)
png(file.path(PATHS$results$qc, 'density_probes_norm.png'), width=1200, height=800, res=140)
plot(density(expr_probes[,1]), main='Densidades (probes) - Normalizado', xlab='Expresión (log2)', ylab='Densidad')
for (i in 2:ncol(expr_probes)) lines(density(expr_probes[,i]))
dev.off()

# 4) PCA (genes) - usar genes más variables para estabilidad
expr_gene_mat <- expr_genes

# seleccionar top 2000 genes más variables
vars <- apply(expr_gene_mat, 1, var, na.rm=TRUE)
topN <- names(sort(vars, decreasing=TRUE))[1:min(2000, length(vars))]
mat <- t(expr_gene_mat[topN, , drop=FALSE])  # samples x genes

pca <- prcomp(mat, center=TRUE, scale.=TRUE)

pca_df <- data.table(
  sample_id = rownames(pca$x),
  PC1 = pca$x[,1],
  PC2 = pca$x[,2]
)
pca_df <- merge(pca_df, ss[, .(sample_id, group)], by='sample_id', all.x=TRUE)

# var explicada
var_exp <- (pca$sdev^2) / sum(pca$sdev^2)
pc1_lab <- sprintf('PC1 (%.1f%%)', 100*var_exp[1])
pc2_lab <- sprintf('PC2 (%.1f%%)', 100*var_exp[2])

# PCA plot (base R, sin depender de ggplot)
png(file.path(PATHS$results$exploratory, 'pca_PC1_PC2.png'), width=1100, height=850, res=140)
plot(pca_df$PC1, pca_df$PC2, pch=19,
     xlab=pc1_lab, ylab=pc2_lab, main='PCA (top var genes)')
legend('topright', legend=unique(pca_df$group), pch=19)
text(pca_df$PC1, pca_df$PC2, labels=pca_df$sample_id, cex=0.5, pos=3)
dev.off()

# 5) Guardar tabla PCA
fwrite(pca_df, file.path(PATHS$results$exploratory, 'pca_scores.tsv'), sep='\t')

message('✅ QC + Exploratorio completado: results/qc y results/exploratory')
