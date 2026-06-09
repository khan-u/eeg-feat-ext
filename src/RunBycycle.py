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


def main() -> None:
    import matlab.engine

    m_threshold_kwargs = {
        'amp_fraction_threshold': 0.2,
        'amp_consistency_threshold': 0.1,
        'period_consistency_threshold': 0.4,
        'monotonicity_threshold': 0.4,
        'min_n_cycles': 3
    }

    xlim = [-0.3, 2.8]
    fs = 400
    f_theta = (3, 7)
    f_lowpass = 30

    parser = argparse.ArgumentParser(description='Run bycycle analysis.')
    parser.add_argument('--csv_path',         type=str, required=True,  help='Path for CSV output')
    parser.add_argument('--preProcessedPath', type=str, required=True,  help='Path to pre-processed .mat files')
    parser.add_argument('--meta_data_path',   type=str, required=True,  help='Path to metaDataExt.mat')
    parser.add_argument('--log_file_path',    type=str, required=False, default='RunBycycle.log')
    args = parser.parse_args()

    csv_path          = args.csv_path
    preProcessedPath  = args.preProcessedPath
    meta_data_path    = args.meta_data_path
    log_file_path     = args.log_file_path

    pathlib.Path(log_file_path).mkdir(parents=True, exist_ok=True)
    timestamp     = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_file_path = os.path.join(log_file_path, f"PythonLog_{timestamp}.log")
    setup_logging(log_file_path)

    logging.info("Starting MATLAB engine...")
    try:
        eng = matlab.engine.start_matlab()
    except Exception as e:
        logging.error(f"Failed to start MATLAB engine: {e}", exc_info=True)
        exit(1)

    try:
        logging.info(f"Loading meta data file: {meta_data_path}")
        eng.load(meta_data_path, nargout=0)
        available_vars = eng.eval("who")

        if isinstance(available_vars, str):
            available_vars_list = available_vars.splitlines()
        elif isinstance(available_vars, list):
            available_vars_list = available_vars
        else:
            available_vars_list = []
            logging.warning(f"Unexpected type for 'who' output: {type(available_vars)}")

        logging.debug(f"Variables in MATLAB workspace: {available_vars_list}")

        if 'metaDataExt' not in available_vars_list:
            raise KeyError(
                f"'metaDataExt' not found in MATLAB workspace. "
                f"Available variables: {available_vars_list}"
            )

        metaDataExt = eng.workspace['metaDataExt']
        logging.info(f"Converting MATLAB struct to Python dictionary...")
        metaDataExt_py = struct2dict(metaDataExt)

    except Exception as e:
        logging.error(f"Error loading meta data via MATLAB engine: {e}", exc_info=True)
        try:
            eng.quit()
        except Exception:
            pass
        exit(1)

    try:
        eng.quit()
        logging.info("MATLAB engine stopped.")
    except Exception as e:
        logging.warning(f"Error stopping MATLAB engine: {e}", exc_info=True)

    included_subject_ids = metaDataExt_py.get('includedSubjectIDs', None)
    if included_subject_ids is None:
        logging.error("'includedSubjectIDs' not found in metaDataExt.")
        exit(1)

    if isinstance(included_subject_ids, (list, tuple)):
        sessionIDarr = [str(item) for item in included_subject_ids]
    else:
        sessionIDarr = [str(included_subject_ids)]

    logging.info(f"Included Subject IDs: {sessionIDarr}")

    final_selected_regions = metaDataExt_py.get('finalSelectedRegions', None)
    if final_selected_regions is None:
        logging.error("'finalSelectedRegions' not found in metaDataExt.")
        exit(1)

    if isinstance(final_selected_regions, (list, tuple)):
        final_selected_regions = flatten_regions(final_selected_regions)
    else:
        final_selected_regions = [str(final_selected_regions)]

    logging.info(f"Final Selected Regions: {final_selected_regions}")

    for session_id in sessionIDarr:
        pt_feature_dir = pathlib.Path(csv_path, session_id)
        try:
            pt_feature_dir.mkdir(parents=True, exist_ok=True)
            logging.info(f"Created directory: {pt_feature_dir}")
        except Exception as e:
            logging.error(f"Failed to create directory {pt_feature_dir}: {e}", exc_info=True)
            continue

    _run_sessions(sessionIDarr, final_selected_regions, csv_path, preProcessedPath,
                  m_threshold_kwargs, fs, f_lowpass, f_theta, xlim)


def _run_sessions(sessionIDarr, final_selected_regions, csv_path, preProcessedPath,
                  m_threshold_kwargs, fs, f_lowpass, f_theta, xlim):
    pass


if __name__ == "__main__":
    overall_start_time = time.time()
    try:
        main()
    except Exception as e:
        logging.error(f"Unexpected error during script execution: {e}", exc_info=True)
    finally:
        overall_end_time = time.time()
        total_time = overall_end_time - overall_start_time
        hours, rem = divmod(total_time, 3600)
        minutes, seconds = divmod(rem, 60)
        logging.info(f"Script completed in {int(hours)}h {int(minutes)}m {int(seconds)}s.")
