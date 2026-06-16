[![Python 3.9–3.12](https://img.shields.io/badge/Python-3.9–3.12-blue.svg)](#installation)

# eeg-feat-ext
**eeg-feat-ext** transforms large-scale human iEEG into **cycle-level theta waveform features** (CSV) so you can test whether observed **theta–high gamma phase–amplitude coupling (PAC)** effects are driven by **nonsinusoidal waveform shape (harmonics)** or reflect **task-related neural dynamics**.

This repository is built to reproduce and extend the **theta waveform-shape control analysis** reported in:

> Daume et al., *Nature* (2024) — "Control of working memory by phase–amplitude coupling of human hippocampal neurons"  
> https://www.nature.com/articles/s41586-024-07309-z  
> Extended Data Fig. 3c (theta waveform-shape control in hippocampal PAC channels)

---

## What Problem This Solves
PAC can be inflated by **nonsinusoidal low-frequency waveforms** (sharp peaks/troughs, asymmetric rises/decays) that generate harmonics and create *spurious* coupling.

**eeg-feat-ext** extracts theta cycle morphology using **bycycle** and exports structured CSVs so you can:
- quantify waveform shape per cycle
- aggregate per channel / condition (e.g., load 1 vs load 3)
- run the waveform-shape control test described in Daume et al. (2024)

---

## Hypotheses
### Null Hypothesis (waveform-shape confound)
**H₀:** Load-related differences in hippocampal theta–high gamma PAC are explained by **load-dependent differences in theta waveform shape** (nonsinusoidality).

**Prediction:** Theta waveform shape metrics differ between load conditions in the same channels/periods used for PAC.

### Alternative Hypothesis (not explained by waveform shape)
**H₁:** Load-related PAC differences are **not explained entirely** by theta waveform-shape artifacts.

**Prediction:** Theta waveform shape metrics do **not** show systematic load differences (and/or PAC effects persist after controlling for shape metrics).

---

## Published Validation Target (Extended Data Fig. 3c)
Extended Data Fig. 3c tests whether theta waveform shape explains PAC differences by comparing:
- **peak-to-trough asymmetry**
- **rise-to-decay asymmetry**

computed from theta cycles during the **maintenance period**, using **the same trials used for PAC**, and comparing load 1 vs load 3 with a **two-sided permutation-based paired t-test** across **n = 137** significant hippocampal PAC channels.

**Reported Outcome (paper):**
- no systematic differences between loads for either asymmetry metric
- average theta waveforms were overall symmetric (both measures were not significantly different from **0.5** in either condition)

---

## Pipeline Overview
**MATLAB preprocessing → metaDataExt.mat → RunBycycle.py → cycle-level CSV features → optional merged tables**

### Inputs
- `.mat` files containing trial-wise iEEG/LFP (multi-channel)
- metadata per trial (subject, region, condition, time window)

### Outputs
- per-subject, per-region cycle-feature CSVs
- optional merged subject-level CSV
- MATLAB + Python logs for reproducibility

---

## Features Exported (cycle-level)
Computed via **bycycle** (cycle-by-cycle time-domain decomposition):
- peak-to-trough asymmetry
- rise-to-decay asymmetry
- per-cycle amplitude, period, rise/decay times, slopes, etc.

> Note: bycycle asymmetry metrics are bounded (0–1), where ~0.5 indicates symmetry.

---

## Reproducing Extended Data Fig. 3c
### 1) Extract theta cycles and features (this repo)
- filter / select maintenance period segments (same window used for PAC)
- run `RunBycycle.py` to extract cycle-level features into CSVs

### 2) Aggregate per Channel × Load
For each hippocampal PAC channel:
- compute the mean of each asymmetry metric across theta cycles within load 1 and load 3 trials
- you now have paired values per channel: `(asym_load1, asym_load3)`

### 3) Run the Test
Use a **two-sided permutation-based paired test** across channels:
- statistic: mean difference across channels (load 3 − load 1)
- permutation: randomly swap load labels within each channel (paired sign-flip)
- p-value: proportion of permuted |T| ≥ |T_obs|

### Published Result
- peak-to-trough asymmetry: no systematic difference (load 1 ≈ load 3)
- rise-to-decay asymmetry: no systematic difference (load 1 ≈ load 3)
- both measures were not significantly different from 0.5 in either condition

---

## Interpretation Guardrails
- "No systematic differences" is evidence **against** waveform-shape differences as the driver,
  but it does not prove the absence of all possible confounds.
- Always report effect sizes + confidence intervals alongside p-values.

---

## Credits
- **bycycle** — cycle-by-cycle waveform feature extraction (Cole & Voytek, *J. Neurophysiol.*, 2019)  
  Docs: https://bycycle-tools.github.io  
  Paper: https://journals.physiology.org/doi/full/10.1152/jn.00273.2019
- **NeuroDSP** — supporting neural signal processing utilities  
  https://neurodsp-tools.github.io

---

## Environment

```
PYTHONENGINE_DIR=/path/to/MATLAB/extern/engines/python
```

Set `pythonEngineDir` in `MAIN.m` to point to the MATLAB Engine install location for your system before running.

---

## Repository structure
```text
eeg-feat-ext/
├── data/
│   ├── raw/
│   ├── pre-processed/
│   └── cycle_features/
├── figures/
├── logs/
├── recycle/
├── src/
│   ├── bycycle_utils.py
│   ├── call_python_bycycle.m
│   ├── checkMetaDataFile.m
│   ├── compareVersions.m
│   ├── createDirectories.m
│   ├── definePaths.m
│   ├── extractLFP.m
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
