#!/bin/bash
# ============================================================
# QIIME2 Metagenomic Analysis — Atacama Desert Soils
# Curso: Secuenciación y Ómicas de Próxima Generación
# Autora: Caren Moreno | UNIR MUBioinfo 2025-2026
# QIIME2 versión: 2023.9
# ============================================================

# Activar entorno
conda activate qiime2-2023.9

# ----------------------------------------------------------
# PASO 1: Directorio de trabajo y descarga de datos
# ----------------------------------------------------------
mkdir qiime2-atacama && cd qiime2-atacama

wget -O "sample-metadata.tsv" \
  "https://data.qiime2.org/2023.9/tutorials/atacamasoils/sample_metadata.tsv"

mkdir emp-paired-end-sequences

wget -O "emp-paired-end-sequences/forward.fastq.gz" \
  "https://data.qiime2.org/2023.9/tutorials/atacamasoils/10p/forward.fastq.gz"

wget -O "emp-paired-end-sequences/reverse.fastq.gz" \
  "https://data.qiime2.org/2023.9/tutorials/atacamasoils/10p/reverse.fastq.gz"

wget -O "emp-paired-end-sequences/barcodes.fastq.gz" \
  "https://data.qiime2.org/2023.9/tutorials/atacamasoils/10p/barcodes.fastq.gz"

# ----------------------------------------------------------
# PASO 2: Importar datos como artefacto QIIME2
# ----------------------------------------------------------
qiime tools import \
  --type EMPPairedEndSequences \
  --input-path emp-paired-end-sequences \
  --output-path emp-paired-end-sequences.qza

# ----------------------------------------------------------
# PASO 3: Demultiplexar lecturas
# ----------------------------------------------------------
qiime demux emp-paired \
  --m-barcodes-file sample-metadata.tsv \
  --m-barcodes-column barcode-sequence \
  --p-rev-comp-mapping-barcodes \
  --i-seqs emp-paired-end-sequences.qza \
  --o-per-sample-sequences demux-full.qza \
  --o-error-correction-details demux-details.qza

# ----------------------------------------------------------
# PASO 4: Submuestra (30% de los datos)
# ----------------------------------------------------------
qiime demux subsample-paired \
  --i-sequences demux-full.qza \
  --p-fraction 0.3 \
  --o-subsampled-sequences demux-subsample.qza

qiime demux summarize \
  --i-data demux-subsample.qza \
  --o-visualization demux-subsample.qzv

# ----------------------------------------------------------
# PASO 5: Filtrar muestras con < 100 reads
# ----------------------------------------------------------
qiime tools export \
  --input-path demux-subsample.qzv \
  --output-path ./demux-subsample/

qiime demux filter-samples \
  --i-demux demux-subsample.qza \
  --m-metadata-file ./demux-subsample/per-sample-fastq-counts.tsv \
  --p-where 'CAST([forward sequence count] AS INT) > 100' \
  --o-filtered-demux demux.qza

# ----------------------------------------------------------
# PASO 6: Control de calidad y denoising con DADA2
# Parámetros modificados: trim-left 13 (eliminar barcodes/adaptadores)
# trunc-len 150 (longitud uniforme de lecturas)
# ----------------------------------------------------------
qiime dada2 denoise-paired \
  --i-demultiplexed-seqs demux.qza \
  --p-trim-left-f 13 \
  --p-trim-left-r 13 \
  --p-trunc-len-f 150 \
  --p-trunc-len-r 150 \
  --o-table table.qza \
  --o-representative-sequences rep-seqs.qza \
  --o-denoising-stats denoising-stats.qza

# Visualizaciones
qiime feature-table summarize \
  --i-table table.qza \
  --o-visualization table.qzv \
  --m-sample-metadata-file sample-metadata.tsv

qiime feature-table tabulate-seqs \
  --i-data rep-seqs.qza \
  --o-visualization rep-seqs.qzv

qiime metadata tabulate \
  --m-input-file denoising-stats.qza \
  --o-visualization denoising-stats.qzv

# ----------------------------------------------------------
# PASO 7: Árbol filogenético (MAFFT + FastTree)
# ----------------------------------------------------------
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences rep-seqs.qza \
  --o-alignment aligned-rep-seqs.qza \
  --o-masked-alignment masked-aligned-rep-seqs.qza \
  --o-tree unrooted-tree.qza \
  --o-rooted-tree rooted-tree.qza

# Exportar árbol en formato Newick
mkdir -p Visualizacion
qiime tools export \
  --input-path rooted-tree.qza \
  --output-path Visualizacion/

# ----------------------------------------------------------
# PASO 8: Diversidad alfa y beta
# Parámetro modificado: --p-sampling-depth 400
# (valor seleccionado para retener 49/54 muestras = 90.74%)
# ----------------------------------------------------------
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny rooted-tree.qza \
  --i-table table.qza \
  --p-sampling-depth 400 \
  --m-metadata-file sample-metadata.tsv \
  --output-dir core-metrics-results

# --- Alpha diversity significance ---
# Faith PD (riqueza filogenética)
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/faith_pd_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/faith-pd-group-significance.qzv

# Shannon (riqueza + equidad)
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/shannon_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/shannon-group-significance.qzv

# Pielou evenness (igualdad)
qiime diversity alpha-group-significance \
  --i-alpha-diversity core-metrics-results/evenness_vector.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization core-metrics-results/evenness-group-significance.qzv

# --- Beta diversity: PERMANOVA ---
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column transect-name \
  --o-visualization core-metrics-results/unweighted-unifrac-transect-name-significance.qzv \
  --p-pairwise

# --- PCoA con eje de profundidad ---
qiime emperor plot \
  --i-pcoa core-metrics-results/unweighted_unifrac_pcoa_results.qza \
  --m-metadata-file sample-metadata.tsv \
  --p-custom-axes depth \
  --o-visualization core-metrics-results/unweighted-unifrac-emperor-depth.qzv

# ----------------------------------------------------------
# PASO 9: Clasificación taxonómica (Greengenes 13_8)
# ----------------------------------------------------------
wget -O "gg-13-8-99-515-806-nb-classifier.qza" \
  "https://data.qiime2.org/2023.9/common/gg-13-8-99-515-806-nb-classifier.qza"

qiime feature-classifier classify-sklearn \
  --i-classifier gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads rep-seqs.qza \
  --o-classification taxonomy.qza

qiime metadata tabulate \
  --m-input-file taxonomy.qza \
  --o-visualization taxonomy.qzv

qiime taxa barplot \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --m-metadata-file sample-metadata.tsv \
  --o-visualization taxa-bar-plots.qzv

# ----------------------------------------------------------
# PASO 10: ANCOM — Análisis diferencial de abundancia
# ----------------------------------------------------------
# A nivel de ASV
qiime composition add-pseudocount \
  --i-table table.qza \
  --o-composition-table comp-table.qza

qiime composition ancom \
  --i-table comp-table.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column extract-group-no \
  --o-visualization ancom-extract-group-no.qzv

# A nivel de género (nivel taxonómico 6)
qiime taxa collapse \
  --i-table table.qza \
  --i-taxonomy taxonomy.qza \
  --p-level 6 \
  --o-collapsed-table table-l6.qza

qiime composition add-pseudocount \
  --i-table table-l6.qza \
  --o-composition-table comp-table-l6.qza

qiime composition ancom \
  --i-table comp-table-l6.qza \
  --m-metadata-file sample-metadata.tsv \
  --m-metadata-column extract-group-no \
  --o-visualization l6-ancom-extract-group-no.qzv

# ============================================================
# FIN DEL ANÁLISIS
# Visualizar archivos .qzv en: https://view.qiime2.org
# ============================================================
