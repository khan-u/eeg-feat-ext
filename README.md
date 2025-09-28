[![Python 3.9–3.12](https://img.shields.io/badge/Python-3.9–3.12-blue.svg)](#installation)

**eeg-feat-ext** *transforms large-scale human brain recordings into clean, structured features — ready for downstream analysis, predictive modeling, and real-time monitoring pipelines.*

---
## Credits

* **Bycycle** — Cycle-by-cycle feature extraction by Cole & Voytek, *Journal of Neurophysiology (2019)*  
  📘 [Bycycle Docs](https://bycycle-tools.github.io)  
  📘 [NeuroDSP Docs](https://neurodsp-tools.github.io)  
  📘 [Publication](https://journals.physiology.org/doi/full/10.1152/jn.00273.2019)


---

## Application

High-throughput feature extraction code processing 21.8 GiB of raw iEEG data across 36 human subjects. Used in analyses performed in *Nature* Publication (2024).

> *“Control of working memory by phase–amplitude coupling of human hippocampal neurons”*
  📄 [Read Article](https://www.nature.com/articles/s41586-024-07309-z)
  📊 [Published Analysis Figure](https://www.nature.com/articles/s41586-024-07309-z#Fig9)
  📁 [DANDI Dataset](https://dandiarchive.org/dandiset/000673)

---

## Question

Are differences in **oscillatory synchrony (PAC)** between memory loads driven by subtle waveform shape artifacts, or do they reflect true cognitive state dynamics?

**Behavioral Task:** Subjects memorized short lists—1 item (low load) or 3 items (high load)—then judged whether a probe item had appeared in the original list.

**Neural Data:** 21.8 GiB of raw multi-site, multi-regional intracranial EEG data from 36 epilepsy patients.

**Null Hypothesis:** Variation in theta-gamma phase amplitude coupling in the hippocampus does not explain observed differences in cognitive recall under high vs. low memory conditions.

**Our Hypothesis:** Oscillatory synchrony correlation with memory recall performance cannot be explained entirely by spurious waveform artifacts.

> *“To determine the influence of waveform shape on phase–amplitude coupling (PAC)... we used the bycycle (eeg-feat-ext) toolbox... then tested peak-to-trough and rise-to-decay asymmetries across task conditions.”*

---

## Pipeline Mechanics

* **Input:** `.mat` files with multi-channel iEEG signal data from multiple patients with metadata
* **Process:** Extracts waveform cycle-level features from unstructured, noisy iEEG signals
* **Output:** Large-scale, structured **CSV files** ready for signal analytics

---

## Analysis

* Stratify iEEG phase-amplitude cross-frequency metrics by subject condition (low vs. high working memory load)
* Use eeg-feat-ext to extract iEEG waveform features across stratified subject data
* Evaluate whether condition-specific waveform features originate from the same distribution via bootstrapping

  * Randomized one-for-one shuffling of memory load labels to create dummy test statistics
  * Repeat to generate a null distribution
  * Perform t-test to compare true vs. dummy distributions
* **Criterion:** *p* < 0.05 adds statistical credibility that theta-gamma cross-frequency coupling in the hippocampus serves as a candidate biomarker for human memory performance

---

## Key Findings

> “We did not find evidence for any of those factors.”
> — Referring to waveform asymmetries as confounds
>
> “These findings suggest that PAC is related to ongoing WM processes during the maintenance period in the hippocampus.”

* Findings visualized in [**Extended Figure 3**](https://www.nature.com/articles/s41586-024-07309-z#Fig9)

---

## Bycycle Preprocessing Pipeline

| **Bycycle-Computed Feature** | **Description**                                               |
| ---------------------------- | ------------------------------------------------------------- |
| **Waveform decomposition**   | Sub-ms segmentation using Hilbert transform                   |
| **Feature generation**       | Amplitude, symmetry, sharpness, slope, duration per cycle     |
| **Interoperability**         | MATLAB ↔ Python via shared metadata files                     |
| **Big-data scalability**     | Supports real-time analysis on large datasets                 |
| **Output format**            | Structured CSVs per brain region, with optional merged tables |

---

**Overview:** Preprocessing (MATLAB) → `metaDataExt.mat` → `RunBycycle.py` (Python) → Cycle-level CSV features → Merged subject-level CSV

* MATLAB filters and exports trial-wise LFP
* Metadata is extended and passed to Python
* Python extracts per-cycle waveform metrics
* Per-region CSVs are generated after validation
* Subject-level CSVs are created after all region-level files are verified
* Per-region CSVs are saved and then auto-merged per patient
* **Result:** Reproducible, cycle-level waveform feature extraction

---

## Pipeline Extracted Features (.csv)

```
.data/cycle_features
└── SubjectID1/
    ├── BrainRegion2/
    │   └── 📄 SubjectID1_BrainRegion2_bycycle_features_YYYYMMDD_#####_sample.csv
    └── 📄 SubjectID1_merged_bycycle_features_YYYYMMDD_#####_sample.csv
```

---

## Pipeline Generated Logs

| **Log File**                                                                              | **Description**                                              |
| ----------------------------------------------------------------------------------------- | ------------------------------------------------------------ |
| [`MATLAB-console-log_YYYYMMDD_HHMMSS.log`](./logs/MATLAB-console-log_YYYYMMDD_HHMMSS.log) | Full preprocessing, orchestration, and LFP filtering steps   |
| [`PythonLog_YYYYMMDD_HHMMSS.log`](./RunBycycle.log/PythonLog_YYYYMMDD_HHMMSS.log)         | Extraction trace: per-cycle metrics, CSV generation, merging |

---

## TODO

* Multithreading for parallel patient processing
* Support for PyCUDA / GPU

---

## Functional Tree

```text
eeg-feat-ext/                           
├── data/                               
│   ├── raw/                            
│   ├── pre-processed/                  
│   └── cycle_features/                 
│       ├── SubjectID1/                 
│       │   ├── BrainRegion1/           
│       │   └── BrainRegion2/
│       │       └── SubjectID1_BrainRegion2_bycycle_features_YYYYMMDD_#####_sample.csv
│       └── SubjectID2/                 
│           ├── BrainRegion1/
│           └── BrainRegion2/
├── figures/                            
├── logs/                               
│   └── MATLAB-console-log_YYYYMMDD_HHMMSS.log   
├── recycle/                            
├── RunBycycle/                         
│   └── PythonLog_YYYYMMDD_HHMMSS.log   
├── src/                                
│   ├── call_python_bycycle.m           
│   ├── checkMetaDataFile.m             
│   ├── compareVersions.m               
│   ├── createDirectories.m             
│   ├── definePaths.m                   
│   ├── extractLFP.m                    
│   ├── extractMatFilesToText.m         
│   ├── filterSubjectsLFP.m             
│   ├── loadMetaData.m                  
│   ├── logMessage.m                    
│   ├── processSubjects.m               
│   ├── recycleMetaData.m               
│   ├── RunBycycle.py                   
│   ├── saveExtendedMetadata.m          
│   ├── saveFolderTree.m                
│   ├── selectSubjectsAndRegions.m      
│   ├── setupLogging.m                  
│   ├── setupProject.m                  
│   ├── verifyAndMoveFiles.m            
│   ├── verifyProcessedDataFiles.m      
│   └── verifyRawDataFiles.m            
├── MAIN.m                              
├── README.md                           
└── requirements.txt                    
```

---
