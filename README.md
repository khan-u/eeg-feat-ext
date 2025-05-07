
# eeg-feat-ext 🧠  
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  
[![Python 3.9–3.12](https://img.shields.io/badge/Python-3.9–3.12-blue.svg)](#installation)

*Developed for high-throughput electrophysiology data, **eeg-feat-ext** transforms large-scale human brain recordings into clean, structured features — ready for downstream analysis, predictive modeling, and real-time monitoring pipelines.*

## Scalable Feature Engineering for Predictive Time-Series Analytics

**eeg-feat-ext** was purpose-built for high-throughput analysis of 21.8 GiB of raw iEEG data across 36 human subjects, culminating in a **Nature (2024)** publication:  
> *“Control of working memory by phase–amplitude coupling of human hippocampal neurons”*  
📄 [Read Article](https://www.nature.com/articles/s41586-024-07309-z)  
📁 [DANDI Dataset](https://dandiarchive.org/dandiset/000673)

---

##  ❓ The Big Question

**Task**: Subjects memorized short lists—1 item (low load) or 3 items (high load)—then judged whether a probe item had appeared in the original list.

**Hypothesis**: Are differences in **oscillatory synchrony (PAC)** between memory loads driven by subtle waveform shape artifacts, or do they reflect true cognitive state dynamics?

> *“To determine the influence of waveform shape on phase–amplitude coupling (PAC)... we used the bycycle (eeg-feat-ext) toolbox... then tested peak-to-trough and rise-to-decay asymmetries across task conditions.”*

---

## 🔧 What This Pipeline Does

- Extracts **condition-specific neural features** from noisy iEEG signals  
- Controls for waveform artifacts to ensure signal **fidelity**  
- Outputs large-scale, structured **CSV files** ready for ML models and dashboards

---

## 🎯 Why It Matters

- Enables **detection of latent cognitive states** in brain data  
- Statistically separates memory load conditions via waveform metrics  
- Optimized for **production-grade throughput** and reproducibility

---

## ✅ Key Findings

> “We did not find evidence for any of those factors.”  
> — Referring to waveform asymmetries as confounds  
>
> “These findings suggest that PAC is related to ongoing WM processes during the maintenance period in the hippocampus.”

---

## 🚀 Real-World Impact

**Human Cognitive Biomarker Identified:**  
*Coordinated brain oscillations in the hippocampus **track working memory load**.*

- ✅ Ruled out spurious signal artifacts using waveform shape controls  
- ✅ Confirmed **oscillatory synchrony** (PAC) as a reliable index of memory maintenance  
- 📊 Findings visualized in [**Extended Figure 3**](https://www.nature.com/articles/s41586-024-07309-z#Fig9)

---
## ♻️ Transferable Analytics + ML

| Neuroscience Application                        | Industry Parallel                             |
|--------------------------------------------------|-----------------------------------------------|
| Memory classification via waveform shape         | Behavioral segmentation, attention modeling   |
| Phase-amplitude coupling (PAC) as latent signal  | User state dynamics, anomaly detection        |
| High-density iEEG signal processing              | IoT / biosensor analytics                     |
| Multi-subject LFP preprocessing on CPU           | Big data ETL in low-resource environments     |

---
## 📦 Pipeline Highlights

| Feature                | Description                                                    |
|------------------------|----------------------------------------------------------------|
| Waveform decomposition | Sub-ms segmentation using Hilbert transform                    |
| Feature generation     | Amplitude, symmetry, sharpness, slope, duration per cycle      |
| Interoperability       | MATLAB ↔ Python via shared metadata files                      |
| Big-data scalability   | Supports real-time analysis on large datasets                  |
| Output format          | Structured CSVs per brain region, with optional merged tables  |
---
- Hybrid orchestration in **MATLAB + Python**
- Reproducible, cycle-level waveform feature extraction
- Validated on real-world data (21.8 GiB, 36 subjects × 500+ channels)
- Runs entirely on **CPU** — no GPU required
---

## ⚙️ Pipeline Mechanics

-  Preprocessing (MATLAB) → metaDataExt.mat → RunBycycle.py (Python) → Cycle-level CSV features → Merged subject-level CSV
---  
- MATLAB filters and exports trial-wise LFP 
- Metadata is extended and passed to Python
- Python extracts per-cycle waveform metrics
- Per-region CSVs are saved and then auto-merged

---

## 📊 Pipeline-Extracted Features (.csv)

.data/cycle_features<br><br>
└── SubjectID1/<br>
  ├── BrainRegion2/<br>
  │  └── 📄 [`SubjectID1_BrainRegion2_bycycle_features_YYYYMMDD_#####_sample.csv`](./data/cycle_features/SubjectID1/BrainRegion2/SubjectID1_BrainRegion2_bycycle_features_YYYYMMDD_#####_sample.csv)<br>
  └── 📄 [`SubjectID1_merged_bycycle_features_YYYYMMDD_#####_sample.csv`](./data/cycle_features/SubjectID1/SubjectID1_merged_bycycle_features_YYYYMMDD_#####_sample.csv)

----
- Per-region CSVs are generated after validation
- Subject-level CSV created after all region-level files are verified
---  

## 📝 Pipeline-Generated Logs

| Log File                                                                       | Description                                                  
|--------------------------------------------|---------------------------------------------------------------|
| [MATLAB console log](./logs/MATLAB-console-log_YYYYMMDD_HHMMSS.log)          | Full preprocessing, orchestration, and LFP filtering steps    |
| [Python log](./RunBycycle.log/PythonLog_YYYYMMDD_HHMMSS.log)         | Extraction trace: per-cycle metrics, CSV generation, merging                                
---
## Dependencies
**eeg-feat-ext** is built on existing Python tools for neual time-series analytics, these dependencies are listed below:  
- **Bycycle** — Cycle-by-cycle feature extraction by Cole & Voytek, _Journal of Neurophysiology (2019)_ 📘 [Docs](https://bycycle-tools.github.io)  
- **NeuroDSP** — Neural time-series signal processing by Cole et al., _Journal of Open Source Software (2019)_ 📘 [Docs](https://neurodsp-tools.github.io)
---
## ⚙️ Quick Start

1. Clone the source code:
```bash
git clone https://github.com/khan-u/eeg-feat-ext.git
cd eeg-feat-ext
```

2. Install MATLAB-Python Engine (*requires a MATLAB license*)
  ```bash
cd "C:\Program Files\MATLAB\R2024b\extern\engines\python"
python setup.py install
```
3. Run the main pipeline entry point from MATLAB for automated downstream hand-off to Python:

```matlab
MAIN.m
```
---
## 🗂️ Repo Tree   

```text
eeg-feat-ext/                           # Root of the feature-extraction pipeline
├── data/                               # Subject data organized for preprocessing and export
│   ├── raw/                            # Original iEEG/LFP input files (untouched)
│   │   └── .gitkeep                    # Keeps directory version-controlled before data exists
│   ├── pre-processed/                  # MATLAB-filtered LFP trials per region
│   │   └── .gitkeep                    # Placeholder until MATLAB generates data
│   └── cycle_features/                 # Bycycle CSV outputs per subject/region
│       ├── SubjectID1/                 # Example subject container
│       │   ├── BrainRegion1/           # e.g., Hippocampus or Amygdala
│       │   │   └── .gitkeep            # Placeholder before region CSVs exist
│       │   └── BrainRegion2/
│       │       └── SubjectID1_BrainRegion2_bycycle_features_YYYYMMDD_#####_sample.csv
│       │                               # Per-trial, per-channel waveform metrics output
│       └── SubjectID2/                 # Identical structure for each subject
│           ├── BrainRegion1/
│           │   └── .gitkeep
│           └── BrainRegion2/
│               └── .gitkeep
├── figures/                            # (Optional) output plots and analysis figures
│   └── .gitkeep                        # Ensures directory is version-controlled even if empty
├── logs/                               # MATLAB-side logs from MAIN.m and helpers
│   └── MATLAB-console-log_YYYYMMDD_HHMMSS.log   # Full transcript of preprocessing and orchestration steps
├── recycle/                            # Archived metaData.mat snapshots for reproducibility
│   └── .gitkeep                        # Retains directory before first archival entry
├── RunBycycle/                         # Logs from the Python-side Bycycle extraction
│   └── PythonLog_YYYYMMDD_HHMMSS.log   # Bycycle runtime debug/info trace for subject/session runs
├── src/                                # Core logic: hybrid MATLAB + Python pipeline code
│   ├── call_python_bycycle.m           # Calls RunBycycle.py with metaDataExt as input
│   ├── checkMetaDataFile.m             # Verifies presence of expected keys in metaData.mat
│   ├── compareVersions.m               # Reports version drift warnings (MATLAB modules)
│   ├── createDirectories.m             # Sets up output folders and structure
│   ├── definePaths.m                   # Constructs absolute/relative project paths
│   ├── extractLFP.m                    # Loads LFP signals into memory for each trial
│   ├── extractMatFilesToText.m         # (Optional) Writes a human-readable view of .mat contents
│   ├── filterSubjectsLFP.m             # Removes subjects missing required brain-region LFP
│   ├── loadMetaData.m                  # Reads base metaData.mat into MATLAB workspace
│   ├── logMessage.m                    # Simple multi-level logger for structured console output
│   ├── processSubjects.m               # Dynamically builds subject data structs
│   ├── recycleMetaData.m               # Moves current metaData.mat to `/recycle` with timestamp
│   ├── RunBycycle.py                   # 🚀 Python script to compute per-cycle waveform features via Bycycle
│   ├── saveExtendedMetadata.m          # Merges metadata and saves metaDataExt.mat
│   ├── saveFolderTree.m                # (Optional) Prints the full directory structure to .txt
│   ├── selectSubjectsAndRegions.m      # Lets user choose specific sessions/regions to run 
│   ├── setupLogging.m                  # Creates timestamped MATLAB log file
│   ├── setupProject.m                  # Initializes project paths and folder checks
│   ├── verifyAndMoveFiles.m            # Moves data into expected structure if misplaced
│   ├── verifyProcessedDataFiles.m      # Confirms presence of expected .mat LFP trials
│   └── verifyRawDataFiles.m            # Checks raw files are present before MATLAB starts
├── .gitattributes                      # Ensures consistent line endings across platforms
├── LICENSE                             # Open-source MIT license for reuse and modification
├── MAIN.m                              # 🚀 Primary entry script that orchestrates full pipeline from MATLAB
├── README.md                           # This documentation file 
└── requirements.txt                    # Python dependencies (Bycycle, NumPy, Pandas, etc.)
```

---

## 📑 License

MIT License — free for academic and commercial use.
