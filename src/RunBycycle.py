"""
Cycle-by-cycle theta waveform feature extraction using bycycle.

References:
    Cole & Voytek (2019), Journal of Neurophysiology, 122(2), 849-861.
    https://doi.org/10.1152/jn.00273.2019
"""

import os
import re
import glob
import logging
import argparse
import pathlib
import numpy as np
import pandas as pd
import h5py
from typing import List, Dict, Any, Optional, Tuple
from datetime import datetime
import time

from neurodsp.filt import filter_signal
from bycycle.features import compute_features
from bycycle_utils import struct2dict, flatten_regions, validate_csv


def resolve_reference(f_mat: h5py.File, ref: Any) -> Optional[Any]:
    """Resolves an HDF5 object reference to its underlying dataset."""
    if isinstance(ref, h5py.Reference):
        try:
            dataset = f_mat[ref]
            return dataset[()]
        except Exception as e:
            logging.error(f"Failed to resolve reference {ref}: {e}", exc_info=True)
            return None
    else:
        return ref


def get_features(
    trials_all: List[np.ndarray],
    trial_num: int,
    channel_num: int,
    threshold_kwargs: Dict[str, Any],
    fs: int,
    f_lowpass: float,
    f_theta: Tuple[float, float]
) -> Tuple[Optional[pd.DataFrame], Optional[np.ndarray], Optional[np.ndarray]]:
    """
    Extracts bycycle features from a single trial-channel LFP segment.

    Applies a lowpass filter then computes cycle-by-cycle features within
    the theta band. Returns the feature DataFrame and both raw and filtered signals.
    """
    try:
        sig = trials_all[trial_num][:, channel_num]
        logging.debug(f"Extracted signal for trial {trial_num}, channel {channel_num}, shape {sig.shape}.")

        sig_low = filter_signal(sig, fs, 'lowpass', f_lowpass, remove_edges=False)
        logging.debug(f"Applied lowpass filter at {f_lowpass} Hz.")

        df_features = compute_features(sig_low, fs, f_theta, threshold_kwargs=threshold_kwargs)
        logging.debug(f"Computed bycycle features for trial {trial_num}, channel {channel_num}.")

        if not isinstance(df_features, pd.DataFrame):
            df_features = pd.DataFrame(df_features)

        return df_features, sig, sig_low
    except Exception as e:
        logging.error(f"Failed to get features for trial {trial_num}, channel {channel_num}: {e}", exc_info=True)
        return None, None, None


def get_df(
    trials_all: List[np.ndarray],
    all_tuples: List[List[int]],
    threshold_kwargs: Dict[str, Any],
    fs: int,
    f_lowpass: float,
    f_theta: Tuple[float, float]
) -> List[pd.DataFrame]:
    """
    Iterates over all trial-channel pairs and collects bycycle feature DataFrames.
    """
    df_data = []
    for tup in all_tuples:
        trial_num, channel_num = tup
        try:
            df, _, _ = get_features(
                trials_all, trial_num, channel_num,
                threshold_kwargs=threshold_kwargs,
                fs=fs, f_lowpass=f_lowpass, f_theta=f_theta
            )
            if df is not None:
                df_data.append(df)
                logging.debug(f"Features extracted for trial {trial_num}, channel {channel_num}.")
            else:
                logging.warning(f"No features extracted for trial {trial_num}, channel {channel_num}.")
        except Exception as e:
            logging.error(f"Error extracting features for tuple {tup}: {e}", exc_info=True)
            continue
    return df_data


def setup_logging(log_file_path: str) -> None:
    """Configures logging to both a file and the console."""
    logging.basicConfig(
        filename=log_file_path,
        filemode='a',
        format='%(asctime)s - %(levelname)s - %(message)s',
        level=logging.DEBUG
    )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)
    console.setFormatter(logging.Formatter('%(levelname)s - %(message)s'))
    logging.getLogger('').addHandler(console)
    logging.info("Log file initialized successfully.")
