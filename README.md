
# Análisis Transcriptómico Reproducible de la Enfermedad Renal Crónica (ERC)

## Trabajo Fin de Máster (TFM) – Máster Universitario en Bioinformática

## Repositorio asociado al Trabajo Fin de Máster

Este repositorio contiene el código fuente, documentación técnica, resultados reproducibles y materiales complementarios utilizados para el desarrollo del Trabajo Fin de Máster (TFM) del Máster Universitario en Bioinformática de la Universidad Alfonso X el Sabio (UAX).

Su finalidad es garantizar la reproducibilidad computacional, la trazabilidad metodológica y la verificación independiente de los resultados presentados en la memoria final.

**Autor:** Cristian Arias, MD
**Universidad:** Universidad Alfonso X el Sabio (UAX)
**Repositorio GitHub:** [https://github.com/broncox456](https://github.com/broncox456)

---

# Descripción General

Este repositorio contiene el pipeline bioinformático reproducible desarrollado para el Trabajo Fin de Máster (TFM) titulado:

**“Análisis transcriptómico de la enfermedad renal crónica mediante datos públicos de microarrays: identificación de genes diferencialmente expresados y enriquecimiento funcional”.**

El objetivo principal es identificar firmas transcriptómicas asociadas a la enfermedad renal crónica (ERC) e interpretar sus mecanismos biológicos mediante análisis de expresión diferencial y enriquecimiento funcional.

El proyecto ha sido desarrollado siguiendo principios de:

* Reproducibilidad computacional.
* Ciencia abierta.
* Trazabilidad de resultados.
* Documentación metodológica.
* Buenas prácticas en bioinformática.

---

# Descripción del Dataset

**Fuente:** Gene Expression Omnibus (GEO)

**Acceso GEO:** GSE12682

**Plataforma:** GPL571 – Affymetrix Human Genome U133A 2.0 Array

**Tipo de muestra:** Tejido renal humano

**Comparación biológica:** Enfermedad Renal Crónica (ERC) vs Controles

## Distribución de muestras

| Grupo     |  n |
| --------- | -: |
| ERC       | 23 |
| Controles | 29 |
| Total     | 52 |

## Resumen del procesamiento

| Métrica                           |        Valor |
| --------------------------------- | -----------: |
| Probes iniciales                  |       22,277 |
| Genes tras procesamiento          |       13,631 |
| Genes diferencialmente expresados |          365 |
| Umbral estadístico                |   FDR ≤ 0.05 |
| Umbral biológico                  | |log2FC| ≥ 1 |

---

# Objetivo Científico

La enfermedad renal crónica constituye un importante problema de salud pública mundial y se caracteriza por mecanismos moleculares complejos que no siempre son detectables mediante marcadores clínicos convencionales.

Este proyecto utiliza transcriptómica y bioinformática para identificar alteraciones moleculares asociadas a la progresión de la ERC y generar hipótesis biológicas susceptibles de validación futura.

---

# Flujo General del Pipeline

El análisis se ejecuta mediante un pipeline modular desarrollado en R que incluye:

1. Descarga de datos desde GEO.
2. Curación y organización de metadatos.
3. Normalización mediante RMA.
4. Control de calidad.
5. Análisis de Componentes Principales (PCA).
6. Expresión génica diferencial mediante limma.
7. Corrección por comparaciones múltiples (Benjamini–Hochberg).
8. Enriquecimiento funcional GO y KEGG.
9. Generación automática de figuras y tablas.
10. Auditoría de reproducibilidad.

---

# Estructura del Proyecto

```text
ENTREGA_FINAL_TFM/
│
├── archive/
├── config/
├── docs/
├── logs/
├── R/
│   ├── 00_setup.R
│   ├── 01_download.R
│   ├── 02_metadata.R
│   ├── 03_normalize.R
│   ├── 04_qc.R
│   ├── 05_de.R
│   ├── 06_enrichment.R
│   └── 07_figures_tables.R
│
├── results/
│   ├── annexes/
│   ├── enrichment/
│   ├── exploratory/
│   ├── figures/
│   ├── qc/
│   └── tables/
│
├── scripts/
├── README.md
├── LICENSE
├── CITATION.bib
├── renv.lock
├── run_pipeline.ps1
└── audit_final_delivery.ps1
```

---

# Entorno Computacional

## Requisitos

* R ≥ 4.4
* PowerShell ≥ 5.1

## Principales paquetes utilizados

* GEOquery
* oligo
* limma
* clusterProfiler
* org.Hs.eg.db
* AnnotationDbi
* pheatmap
* ggplot2
* dplyr
* readr
* renv

---

# Restauración del Entorno Reproducible

Desde la raíz del proyecto:

```r
if (!requireNamespace("renv", quietly = TRUE))
    install.packages("renv")

renv::restore(prompt = FALSE)
```

---

# Ejecución del Pipeline

Pipeline completo:

```powershell
.\run_pipeline.ps1
```

Alternativamente:

```powershell
Rscript scripts/run_pipeline.R
```

---

# Resultados Generados

## Figuras principales

* PCA
* Volcano Plot
* Heatmap Top30
* Dotplot GO Biological Process
* Dotplot GO Cellular Component
* Dotplot GO Molecular Function
* Dotplot KEGG

## Tablas principales

* DE_all_genes.tsv
* DE_significant_genes.tsv
* TFM_Top20_DE.tsv
* TFM_Top20_UP.tsv
* TFM_Top20_DOWN.tsv
* TFM_GO_BP_Top15.tsv
* TFM_QC_summary.tsv
* TFM_reproducibility_audit.tsv

---

# Reproducibilidad

Este proyecto incorpora múltiples mecanismos de reproducibilidad:

* Gestión de dependencias mediante `renv`.
* Registro de versiones mediante `renv.lock`.
* Scripts modulares documentados.
* Archivos de configuración.
* Registros de ejecución (logs).
* Exportación de `sessionInfo`.
* Auditoría automática de resultados.
* Documento de trazabilidad de outputs.

Los archivos de sesión se almacenan en:

```text
logs/sessionInfo_*.txt
```

---

# Trazabilidad de Resultados

La relación entre cada resultado generado y el script responsable de producirlo se encuentra documentada en:

```text
docs/output_traceability.md
```

Este enfoque garantiza:

* Reproducibilidad.
* Transparencia.
* Auditabilidad.
* Verificación independiente de resultados.

---

# Hallazgos Principales

El análisis transcriptómico identificó una firma molecular compatible con procesos conocidos de progresión de la ERC:

* Activación inflamatoria crónica.
* Remodelado de matriz extracelular.
* Procesos profibróticos.
* Alteraciones metabólicas tubulares.
* Disfunción epitelial renal.

## Principales rutas enriquecidas

* ECM-Receptor Interaction.
* Focal Adhesion.
* TGF-beta Signaling Pathway.
* PI3K-Akt Signaling Pathway.

Estos hallazgos respaldan el papel de la inflamación y la fibrosis como mecanismos centrales en la progresión de la enfermedad renal crónica.

---

# Limitaciones

Los resultados deben interpretarse como un análisis transcriptómico exploratorio basado en datos públicos.

Principales limitaciones:

* Dependencia de la calidad de los metadatos GEO.
* Posibles batch effects residuales.
* Limitaciones inherentes a microarrays.
* Ausencia de resolución unicelular.
* Ausencia de validación experimental externa.
* Ausencia de inferencia causal.
* Ausencia de validación clínica prospectiva.

Por tanto, los hallazgos deben considerarse generadores de hipótesis biológicas y no biomarcadores clínicamente validados.

---

# Nota sobre Archivos Legacy

El archivo:

```text
archive/legacy_analysis.R
```

corresponde a una versión exploratoria previa del análisis y no forma parte del pipeline final reproducible utilizado en este TFM.

La versión oficial del flujo de trabajo está constituida exclusivamente por los módulos contenidos en la carpeta `R/` y los scripts de ejecución documentados en este repositorio.

---

# Autor

**Cristian Arias, MD**

Nefrólogo · Internista · Analista de Datos en Salud

Máster Universitario en Bioinformática

Universidad Alfonso X el Sabio (UAX)

República Dominicana

**Veredicto:** esta versión sí es coherente con tu auditoría, con el profesor, con el repositorio real y con el nivel esperado para una defensa de TFM. Ahora pasaría directamente al **Capítulo 4 del manuscrito**.

