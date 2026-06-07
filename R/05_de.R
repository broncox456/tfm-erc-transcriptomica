# ============================================================
# TFM_ERC_transcriptomica
# Script: R/05_de.R
# Propósito:
#   - Differential Expression (limma) CKD vs Control
#   - Exporta tablas + figuras
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(data.table)
  library(limma)
})

stop_pipeline <- function(msg) stop(glue('❌ DE ERROR: {msg}'), call. = FALSE)

# 1) Config + dirs
PATHS  <- yaml::read_yaml('config/paths.yml')
PARAMS <- yaml::read_yaml('config/params.yml')

dir_create(PATHS$results$differential, recurse = TRUE)
dir_create(PATHS$results$figures, recurse = TRUE)
dir_create(PATHS$results$tables, recurse = TRUE)

# thresholds
fdr_thr  <- PARAMS$analysis$fdr;   if (is.null(fdr_thr))  fdr_thr <- 0.05
logfc_thr<- PARAMS$analysis$logfc; if (is.null(logfc_thr))logfc_thr <- 1.0

# 2) Cargar datos
expr_genes <- readRDS(file.path(PATHS$data$processed, 'exprs_genes_norm.rds'))
ss <- fread(file.path(PATHS$data$processed, 'sample_sheet_aligned.tsv'))

if (!all(c('sample_id','group') %in% names(ss))) stop_pipeline('sample_sheet_aligned.tsv debe tener sample_id y group')

# Alinear
ss <- ss[match(colnames(expr_genes), ss$sample_id)]
stopifnot(all(ss$sample_id == colnames(expr_genes)))

# 3) Definir factor de grupo (Control como referencia)
ss[, group := factor(group, levels = c('Control','CKD'))]
if (any(is.na(ss$group))) stop_pipeline('Hay NA en group; revisa metadata')
if (nlevels(ss$group) != 2) stop_pipeline('Se esperan exactamente 2 grupos: Control y CKD')

message('📊 Conteo por grupo (DE):')
print(table(ss$group))

# 4) Diseño y ajuste
design <- model.matrix(~ 0 + group, data = ss)
colnames(design) <- levels(ss$group)

# Contraste CKD vs Control
contrast <- makeContrasts(CKD_vs_Control = CKD - Control, levels = design)

fit <- lmFit(expr_genes, design)
fit2 <- contrasts.fit(fit, contrast)
fit2 <- eBayes(fit2)

# 5) Tabla completa
tt_all <- topTable(fit2, coef='CKD_vs_Control', number=Inf, sort.by='P')
tt_all <- as.data.table(tt_all, keep.rownames='gene')

# añadir flags
tt_all[, sig := (adj.P.Val <= fdr_thr) & (abs(logFC) >= logfc_thr)]

out_all <- file.path(PATHS$results$tables, 'DE_all_genes.tsv')
fwrite(tt_all, out_all, sep='\t')

# Top genes significativos
tt_sig <- tt_all[sig == TRUE]
out_sig <- file.path(PATHS$results$tables, 'DE_significant_genes.tsv')
fwrite(tt_sig, out_sig, sep='\t')

message(glue('✅ Tabla completa: {out_all}'))
message(glue('✅ Tabla significativos: {out_sig}'))
message(glue('✅ #Significativos (FDR<={fdr_thr}, |logFC|>={logfc_thr}): {nrow(tt_sig)}'))

# 6) Volcano plot (base R)
volcano_path <- file.path(PATHS$results$figures, 'volcano_CKD_vs_Control.png')
png(volcano_path, width=1200, height=900, res=140)
with(tt_all, {
  x <- logFC
  y <- -log10(P.Value)
  plot(x, y, pch=19, cex=0.6, main='Volcano: CKD vs Control', xlab='log2 Fold Change', ylab='-log10(P)')
  abline(v=c(-logfc_thr, logfc_thr), lty=2)
  abline(h=-log10(0.05), lty=2)
  points(x[sig], y[sig], pch=19)
})
dev.off()
message(glue('✅ Volcano: {volcano_path}'))

# 7) Heatmap simple (top 30 por adj.P.Val)
topN <- min(30, nrow(tt_all))
top_genes <- tt_all[1:topN, gene]
mat <- expr_genes[top_genes, , drop=FALSE]

# z-score por gen
mat_z <- t(scale(t(mat)))

hm_path <- file.path(PATHS$results$figures, 'heatmap_top30.png')
png(hm_path, width=1200, height=900, res=140)
par(mar=c(7,7,3,2))
image(
  x = 1:ncol(mat_z),
  y = 1:nrow(mat_z),
  z = t(mat_z[nrow(mat_z):1, ]),
  axes = FALSE,
  main = 'Heatmap (Top 30 genes por P)'
)
axis(1, at=1:ncol(mat_z), labels=ss$group, las=2, cex.axis=0.8)
axis(2, at=1:nrow(mat_z), labels=rev(rownames(mat_z)), las=2, cex.axis=0.6)
dev.off()
message(glue('✅ Heatmap: {hm_path}'))

# 8) Guardar objetos del modelo
saveRDS(list(design=design, contrast=contrast, fit2=fit2), file.path(PATHS$results$differential, 'limma_model.rds'))
message('✅ DE COMPLETO (limma)')
