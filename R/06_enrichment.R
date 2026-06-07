# ============================================================
# TFM_ERC_transcriptomica
# Script: R/06_enrichment.R
# Propósito:
#   - Enriquecimiento funcional (GO + KEGG) desde DE_significant_genes.tsv
#   - Exporta tablas y figuras
# ============================================================

suppressPackageStartupMessages({
  library(yaml)
  library(fs)
  library(glue)
  library(data.table)
  library(clusterProfiler)
  library(org.Hs.eg.db)
  library(enrichplot)
})

stop_pipeline <- function(msg) stop(glue('❌ ENRICH ERROR: {msg}'), call. = FALSE)

PATHS  <- yaml::read_yaml('config/paths.yml')
PARAMS <- yaml::read_yaml('config/params.yml')

dir_create(PATHS$results$enrichment, recurse = TRUE)
dir_create(PATHS$results$figures, recurse = TRUE)

# thresholds (para reportar)
fdr_thr  <- PARAMS$analysis$fdr;   if (is.null(fdr_thr))  fdr_thr <- 0.05
logfc_thr<- PARAMS$analysis$logfc; if (is.null(logfc_thr))logfc_thr <- 1.0

# 1) Cargar genes significativos
sig_path <- file.path(PATHS$results$tables, 'DE_significant_genes.tsv')
if (!file.exists(sig_path)) stop_pipeline(glue('No existe: {sig_path} (corre R/05_de.R)'))

tt_sig <- fread(sig_path)
if (!('gene' %in% names(tt_sig))) stop_pipeline('DE_significant_genes.tsv debe tener columna gene')

# genes como SYMBOL
genes_symbol <- unique(tt_sig$gene)
genes_symbol <- genes_symbol[!is.na(genes_symbol) & genes_symbol != '']

if (length(genes_symbol) < 20) stop_pipeline('Muy pocos genes significativos para enriquecimiento. Revisa thresholds.')

message(glue('✔ Genes significativos para enriquecimiento: {length(genes_symbol)} (FDR<={fdr_thr}, |logFC|>={logfc_thr})'))

# 2) Mapear SYMBOL -> ENTREZID
map <- bitr(genes_symbol, fromType='SYMBOL', toType='ENTREZID', OrgDb=org.Hs.eg.db)
map <- unique(map)
entrez <- unique(map$ENTREZID)

message(glue('✔ Mapeo a ENTREZID: {length(entrez)}'))
if (length(entrez) < 20) stop_pipeline('Mapeo a ENTREZID insuficiente. (Poco mapeo)')

# 3) GO enrichment (BP, MF, CC)
ego_bp <- enrichGO(gene=entrez, OrgDb=org.Hs.eg.db, keyType='ENTREZID', ont='BP', pAdjustMethod='BH', qvalueCutoff=0.2, readable=TRUE)
ego_mf <- enrichGO(gene=entrez, OrgDb=org.Hs.eg.db, keyType='ENTREZID', ont='MF', pAdjustMethod='BH', qvalueCutoff=0.2, readable=TRUE)
ego_cc <- enrichGO(gene=entrez, OrgDb=org.Hs.eg.db, keyType='ENTREZID', ont='CC', pAdjustMethod='BH', qvalueCutoff=0.2, readable=TRUE)

# 4) KEGG enrichment (humano = 'hsa')
ekegg <- tryCatch({
  enrichKEGG(gene=entrez, organism='hsa', pAdjustMethod='BH', qvalueCutoff=0.2)
}, error = function(e) NULL)

# 5) Exportar tablas
export_enrich <- function(obj, out) {
  if (is.null(obj) || nrow(as.data.frame(obj)) == 0) {
    fwrite(data.table(), out, sep='\t')
    return(FALSE)
  }
  fwrite(as.data.table(as.data.frame(obj)), out, sep='\t')
  TRUE
}

bp_path <- file.path(PATHS$results$enrichment, 'GO_BP.tsv')
mf_path <- file.path(PATHS$results$enrichment, 'GO_MF.tsv')
cc_path <- file.path(PATHS$results$enrichment, 'GO_CC.tsv')
kegg_path <- file.path(PATHS$results$enrichment, 'KEGG.tsv')

has_bp <- export_enrich(ego_bp, bp_path)
has_mf <- export_enrich(ego_mf, mf_path)
has_cc <- export_enrich(ego_cc, cc_path)
has_kegg <- export_enrich(ekegg, kegg_path)

message(glue('✅ Tablas enrichment: {PATHS$results$enrichment}'))

# 6) Figuras (dotplot) - solo si hay resultados
make_dot <- function(obj, filename, title) {
  if (is.null(obj) || nrow(as.data.frame(obj)) == 0) return(FALSE)
  png(filename, width=1400, height=900, res=140)
  print(dotplot(obj, showCategory=15) + ggplot2::ggtitle(title))
  dev.off()
  TRUE
}

bp_fig <- file.path(PATHS$results$figures, 'dotplot_GO_BP.png')
mf_fig <- file.path(PATHS$results$figures, 'dotplot_GO_MF.png')
cc_fig <- file.path(PATHS$results$figures, 'dotplot_GO_CC.png')
kegg_fig <- file.path(PATHS$results$figures, 'dotplot_KEGG.png')

make_dot(ego_bp, bp_fig, 'GO Biological Process (CKD vs Control)')
make_dot(ego_mf, mf_fig, 'GO Molecular Function (CKD vs Control)')
make_dot(ego_cc, cc_fig, 'GO Cellular Component (CKD vs Control)')
if (!is.null(ekegg)) make_dot(ekegg, kegg_fig, 'KEGG pathways (CKD vs Control)')

message('✅ ENRIQUECIMIENTO COMPLETO')
