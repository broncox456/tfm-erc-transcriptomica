# Trazabilidad de Outputs

Este documento relaciona los principales outputs del proyecto con los scripts o etapas que los generan. Su objetivo es garantizar reproducibilidad, trazabilidad y auditabilidad del análisis.

| Output | Tipo | Etapa / Script de origen | Propósito |
|---|---|---|---|
| results/figures/TFM_PCA.png | Figura | R/04_qc.R | Análisis de componentes principales y evaluación exploratoria |
| results/figures/TFM_Volcano.png | Figura | R/05_de.R | Visualización global de expresión diferencial |
| results/figures/TFM_Heatmap_Top30.png | Figura | R/07_figures_tables.R | Visualización de los genes principales diferencialmente expresados |
| results/figures/TFM_GO_BP_Dotplot.png | Figura | R/06_enrichment.R | Enriquecimiento funcional GO Biological Process |
| results/figures/dotplot_GO_CC.png | Figura | R/06_enrichment.R | Enriquecimiento GO Cellular Component |
| results/figures/dotplot_GO_MF.png | Figura | R/06_enrichment.R | Enriquecimiento GO Molecular Function |
| results/figures/dotplot_KEGG.png | Figura | R/06_enrichment.R | Enriquecimiento funcional KEGG |
| results/tables/DE_all_genes.tsv | Tabla | R/05_de.R | Resultados completos de expresión diferencial |
| results/tables/DE_significant_genes.tsv | Tabla | R/05_de.R | Genes diferencialmente expresados significativos |
| results/tables/TFM_Top20_DE.tsv | Tabla | R/07_figures_tables.R | Top 20 genes diferencialmente expresados |
| results/tables/TFM_Top20_UP.tsv | Tabla | R/07_figures_tables.R | Top 20 genes sobreexpresados |
| results/tables/TFM_Top20_DOWN.tsv | Tabla | R/07_figures_tables.R | Top 20 genes infraexpresados |
| results/tables/TFM_GO_BP_Top15.tsv | Tabla | R/06_enrichment.R | Principales términos GO Biological Process |
| results/tables/TFM_QC_summary.tsv | Tabla | R/04_qc.R | Resumen de control de calidad |
| results/tables/TFM_reproducibility_audit.tsv | Tabla | scripts/validate_project_outputs.R | Evidencia de auditoría reproducible |
