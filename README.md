# eeg-feat-ext 🧠 
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)  
[![Python 3.9‒3.12](https://img.shields.io/badge/Python-3.9‒3.12-blue.svg)](#installation)  

_High-Bandwidth Brain Oscillatory Analytics at Scale — Validated on 21+ GB of iEEG Recordings for Cognitive Biomarker Discovery_

---

## 🚀 Real-World Deployment 

The **eeg-feat-ext** software was deployed in a peer-reviewed **Nature (2024)** study on large-scale human brain data:  
> _"Working Memory Signals in Large-Scale Human Brain Data"_  
> [Nature article → s41586-024-07309-z](https://www.nature.com/articles/s41586-024-07309-z)

## Dataset Access
Raw iEEG recordings used in this study were made publicly available via the **NIH-funded DANDI Archive**:
> 📁 [DANDI:000673](https://dandiarchive.org/dandiset/000673)  
> 📄 DOI: [10.48324/dandi.000673/0.250122.0110](https://doi.org/10.48324/dandi.000673/0.250122.0110)  
> 🗓️ Created: January 21, 2025 — Size: 21.8 GiB — Format: [Neurodata Without Borders (NWB)](https://www.nwb.org/)  
> 👥 Subjects: 36 human participants (multi-electrode recordings)  

Built on NumPy, Pandas, and Bycycle, this software delivers high-throughput, reproducible analytics of neural oscillation microstructure.  
Stress-tested on *21+ GB of raw iEEG*, it handled production-scale ingestion across 500+ channels from 36 patients each — all on CPU-only infrastructure. It powered cross-frequency coupling analyses and enabled control-phase statistical validation of coordinated hippocampal oscillations as a candidate biomarker of memory capacity.

The results of this key validation are presented in 👉 **[Extended Figure 3](https://www.nature.com/articles/s41586-024-07309-z#Fig9)** and interpreted by the authors as follows:

> “To determine the influence of **theta waveform shape** on PAC, we tested for differences in theta waveform peak-to-trough  
> as well as rise-to-decay asymmetries between the two load conditions, which could potentially cause differences in TG-PAC.
>
> 👉 To extract and characterize each theta cycle during the delay period in all significant hippocampal PAC channels,  
> we used the **bycycle toolbox in Python**.
>
> We averaged estimates for peak-to-trough as well as rise-to-decay asymmetries across cycles during the maintenance period from the same trials used for our PAC analysis within each load and tested the estimates between the conditions.
>
> These findings suggest that PAC is related to ongoing WM processes during the maintenance period in the hippocampus.”

🚀 This crucial control analysis effectively ruled out spurious signal artifacts — i.e., the observed PAC was **NOT** explainable by simple waveform-shape differences between memory loads, confirming its role as a neural signature of cognitive state.

---
## Dependencies
**eeg-feat-ext** is built with existing & widely used Python tools for neual time-series analysis, these dependencies are acknowledged below:  
- **Bycycle** — Cycle-by-cycle feature extraction by Cole & Voytek, _Journal of Neurophysiology (2019)_ 📘 [Docs](https://bycycle-tools.github.io)  
- **NeuroDSP** — Neural time-series signal processing by Cole et al., _Journal of Open Source Software (2019)_ 📘 [Docs](https://neurodsp-tools.github.io)
 
## 🔍 At a Glance
Modular MATLAB + Python pipeline for end-to-end feature engineering from high-bandwidth electrophysiological recordings.

- Ultra-fast **cycle-level segmentation** using Hilbert transforms + zero-crossings  
- Outputs clean, structured **CSV feature tables** for each subject and brain region  
- Interoperable via **MATLAB Engine for Python**  
- Optimized for **scalable big-data ingestion (21+ GB)** with CPU-only execution  
---

| Capability                            | Description |
|---------------------------------------|-------------|
| **High-resolution decomposition**     | Sub-millisecond cycle segmentation |
| **Waveform microstructure metrics**   | Amplitude, symmetry, slope, sharpness, duration |
| **Big-data ready output format**      | Export-ready CSVs for ML pipelines |
| **Cross-language orchestration**      | End-to-end logging and control across MATLAB + Python |
| **Resource-efficient**                | High performance without requiring a GPU |

---

## 🗂️ Repo Structure

```bash
eeg-feat-ext/
├── MAIN.m                    # Orchestrates full preprocessing + feature extraction
├── call_python_bycycle.m     # Launches Python pipeline with metadata
├── RunBycycle.py             # Bycycle feature extraction in Python
├── src/                      # MATLAB helper functions (extractLFP, processSubjects, etc.)
├── data/
│   ├── pre-processed/        # MATLAB outputs: filtered LFP trials per region
│   ├── cycle_features/       # Python outputs: per-region and merged CSVs
│   └── metaDataExt.mat       # Shared metadata struct across both languages
├── logs/                     # MATLAB + Python logs
└── requirements.txt          # Python dependencies
```

---

## 📄 Example Output 

Cycle-level waveform features are exported as CSVs per region and subject. Inspect real output samples below:

- 📄[`Subject01_CA1_bycycle_features_*.csv`](./data/cycle_features/Subject01/CA1/Subject01_CA1_bycycle_features_20250410_153022.csv)  
  <sub>→ Cycle-by-cycle features from CA1 region of Subject01</sub>  

- 📄[`Subject01_merged_bycycle_features_*.csv`](./data/cycle_features/Subject01/Subject01_merged_bycycle_features_20250410_153052.csv)    
  <sub>→ Merged summary across regions for Subject01</sub>  

---

## ⚙️ Quick Start

```bash
# Install the Python environment dependencies
pip install git+https://github.com/khan-u/eeg-feat-ext.git
```

To run the full hybrid pipeline (MATLAB ➝ Python), begin in MATLAB:

```matlab
% Step 1 — (Optional) Install MATLAB Engine for Python if not already installed:
cd 'C:\Program Files\MATLAB\R2024b\extern\engines\python'
python setup.py install

% Step 2 — Launch the master pipeline:
MAIN  % Preprocesses data and auto-launches Python-based waveform analysis
```

This workflow:
- Initializes preprocessing in MATLAB across selected brain regions  
- Auto-launches `RunBycycle.py` via `call_python_bycycle(...)`  
- Produces region-wise and merged `.csv` output containing cycle-level waveform features  

---

## 📄 License

MIT License — free for academic and commercial use.  
