# metagenomic-analysis-qiime2
A detailed qiime2 pipeline for 16S rRNA microbiome and metagenomic data analysis

# Structure
```text
metagenomic-analysis-qiime2/
│
├── README.md
├── LICENSE
│
├── data/
│   ├── metadata/
│   │   └── sample-metadata.tsv
│   │
│   └── processed/
│       ├── table.qza
│       ├── rep-seqs.qza
│       ├── rooted-tree.qza
│       └── taxonomy.qza
│
├── results/
│   ├── alpha-diversity/
│   │   ├── faith-pd-group-significance.qzv
│   │   ├── shannon-group-significance.qzv
│   │   └── evenness-group-significance.qzv
│   │
│   ├── beta-diversity/
│   │   ├── unweighted-unifrac-transect-name-significance.qzv
│   │   └── unweighted-unifrac-emperor-depth.qzv
│   │
│   ├── taxonomy/
│   │   ├── taxonomy.qzv
│   │   └── taxa-bar-plots.qzv
│   │
│   └── ancom/
│       ├── ancom-extract-group-no.qzv
│       └── l6-ancom-extract-group-no.qzv
│
├── figures/
│   ├── alpha_faith_pd.png
│   ├── alpha_shannon.png
│   ├── alpha_evenness.png
│   ├── permanova.png
│   ├── taxa_barplot_level2.png
│   ├── taxa_barplot_level6.png
│   ├── ancom_otu.png
│   └── ancom_genus.png
│
├── scripts/
│   └── qiime2_workflow.sh
│
└── report/
    └── Informe_Metagenomica_QIIME2.pdf
```

# License 
License MIT
