"""
Author: Umais Khan

Description:
This Python script implements neural oscillation analysis using NeuroDSP and ByCycle tools. 
It includes customized methods for cycle-by-cycle analysis based on Cole & Voytek (2019). 
The work here integrates openly accessible Python packages for neural signal processing.

References:
1. Cole, S., & Voytek, B. (2019). Cycle-by-cycle analysis of neural oscillations. 
   Journal of Neurophysiology, 122(2), 849-861. https://doi.org/10.1152/jn.00273.2019  
   ByCycle Documentation: https://bycycle-tools.github.io/bycycle/

2. Cole, S., Donoghue, T., Gao, R., & Voytek, B. (2019). NeuroDSP: A package for 
   neural digital signal processing. Journal of Open Source Software, 4(36), 1272. 
   https://doi.org/10.21105/joss.01272  
   NeuroDSP Documentation: https://neurodsp-tools.github.io/
"""

# Import necessary libraries
import os
import re  # For regex operations and label sanitization
import glob
import logging
import argparse
import pathlib
import numpy as np
import pandas as pd
import scipy.io
import h5py
from tqdm import tqdm  # For progress tracking
from typing import List, Dict, Any, Optional, Tuple
import copy  # For deep copying objects
import matlab.engine  # MATLAB Engine API for Python
import warnings
from neurodsp.filt import filter_signal
from bycycle.features import compute_features
from datetime import datetime  # For timestamp generation
import time  # For script execution timing


def struct2dict(s: Any) -> Any:
    """
    Recursively converts a MATLAB struct or list to a Python dictionary.

    Args:
        s (Any): The MATLAB struct, list, or scalar to convert.

    Returns:
        Any: A Python dictionary, list, or scalar equivalent of the input.
    """
    if isinstance(s, dict):
        return {k: struct2dict(v) for k, v in s.items()}
    elif isinstance(s, list):
        return [struct2dict(item) for item in s]
    elif isinstance(s, float) or isinstance(s, int):
        return s
    elif isinstance(s, str):
        return s
    else:
        return s


def setup_logging(log_file_path: str) -> None:
    """
    Sets up logging for the script, directing logs to both a file and the console.

    Args:
        log_file_path (str): The full path to the log file where logs will be written.

    Returns:
        None
    """
    logging.basicConfig(
        filename=log_file_path,
        filemode='a',
        format='%(asctime)s - %(levelname)s - %(message)s',
        level=logging.DEBUG  # Capture all log levels
    )
    console = logging.StreamHandler()
    console.setLevel(logging.INFO)  # Console displays INFO and above
    formatter = logging.Formatter('%(levelname)s - %(message)s')
    console.setFormatter(formatter)
    logging.getLogger('').addHandler(console)
    logging.info("Log file initialized successfully.")
    logging.debug(f"Logging setup complete. Log file path: {log_file_path}")

# Function to flatten the final_selected_regions list
def flatten_regions(regions):
    flat_list = []
    for item in regions:
        if isinstance(item, (list, tuple)):
            flat_list.extend(flatten_regions(item))  # Recursively flatten
        else:
            flat_list.append(str(item))
    return flat_list

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
    Extracts Bycycle features from the LFP signal for a specific trial and channel.

    This function applies a lowpass filter to the raw LFP signal, computes Bycycle features
    within the theta band, and returns the resulting DataFrame along with the original and
    filtered signals.

    Args:
        trials_all (List[np.ndarray]): A list of LFP data arrays for all trials.
            Each element in the list corresponds to a trial and is a 2D NumPy array
            with shape (samples, channels).
        trial_num (int): The index of the trial to process.
        channel_num (int): The index of the channel within the trial to process.
        threshold_kwargs (Dict[str, Any]): Parameters for thresholding in feature computation.
            Example keys:
                - 'amp_fraction_threshold'
                - 'amp_consistency_threshold'
                - 'period_consistency_threshold'
                - 'monotonicity_threshold'
                - 'min_n_cycles'
        fs (int): Sampling frequency of the LFP data in Hz.
        f_lowpass (float): Cutoff frequency for the lowpass filter in Hz.
        f_theta (Tuple[float, float]): Frequency range for theta band analysis (low, high) in Hz.

    Returns:
        Tuple[Optional[pd.DataFrame], Optional[np.ndarray], Optional[np.ndarray]]:
            - pd.DataFrame or None: DataFrame containing the extracted Bycycle features.
              Returns None if feature extraction fails.
            - np.ndarray or None: The original raw LFP signal for the specified trial and channel.
              Returns None if extraction fails.
            - np.ndarray or None: The lowpass-filtered LFP signal.
              Returns None if filtering fails.
    """
    try:
        # Extract the raw signal for the specified trial and channel
        sig = trials_all[trial_num][:, channel_num]
        logging.debug(f"Extracted raw signal for trial {trial_num}, channel {channel_num} with shape {sig.shape}.")

        # Apply lowpass filter to the signal
        sig_low = filter_signal(sig, fs, 'lowpass', f_lowpass, remove_edges=False)
        logging.debug(f"Applied lowpass filter: f_lowpass={f_lowpass}Hz.")

        # Compute Bycycle features within the theta band
        df_features = compute_features(sig_low, fs, f_theta, threshold_kwargs=threshold_kwargs)
        logging.debug(f"Computed Bycycle features for trial {trial_num}, channel {channel_num}.")

        # Ensure the result is a pandas DataFrame
        if not isinstance(df_features, pd.DataFrame):
            df_features = pd.DataFrame(df_features)
            logging.debug("Converted Bycycle features to pandas DataFrame.")

        return df_features, sig, sig_low
    except Exception as e:
        logging.error(f"Failed to get features for trial {trial_num}, channel {channel_num}: {e}", exc_info=True)
        return None, None, None  # Return None if any step fails


def get_df(
    trials_all: List[np.ndarray],
    all_tuples: List[List[int]],
    threshold_kwargs: Dict[str, Any],
    fs: int,
    f_lowpass: float,
    f_theta: Tuple[float, float]
) -> List[pd.DataFrame]:
    """
    Generates a list of feature DataFrames for all trial-channel combinations.

    Args:
        trials_all (List[np.ndarray]): A list of LFP data arrays for all trials.
            Each element in the list corresponds to a trial and is a 2D NumPy array
            with shape (samples, channels).
        all_tuples (List[List[int]]): A list of [trial_num, channel_num] pairs indicating
            which trials and channels to process.
        threshold_kwargs (Dict[str, Any]): Parameters for thresholding in feature computation.
        fs (int): Sampling frequency of the LFP data in Hz.
        f_lowpass (float): Cutoff frequency for the lowpass filter in Hz.
        f_theta (Tuple[float, float]): Frequency range for theta band analysis (low, high) in Hz.

    Returns:
        List[pd.DataFrame]: A list of DataFrames, each containing features for a specific trial-channel pair.
    """
    df_data = []
    for idx, tup in enumerate(all_tuples):
        trial_num, channel_num = tup
        try:
            df, _, _ = get_features(
                trials_all,
                trial_num,
                channel_num,
                threshold_kwargs=threshold_kwargs,
                fs=fs,
                f_lowpass=f_lowpass,
                f_theta=f_theta
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


def resolve_reference(f_mat: h5py.File, ref: Any) -> Optional[Any]:
    """
    Resolves an object reference in HDF5 to its actual dataset.

    Args:
        f_mat (h5py.File): The opened HDF5 .mat file.
        ref (Any): The reference to resolve, typically an h5py.Reference.

    Returns:
        Any or None: The dataset referenced by `ref`, or None if resolution fails.
    """
    if isinstance(ref, h5py.Reference):
        try:
            dataset = f_mat[ref]
            return dataset[()]
        except Exception as e:
            logging.error(f"Failed to resolve reference {ref}: {e}", exc_info=True)
            return None
    else:
        return ref


def validate_csv(
    file_path: str,
    expected_columns: Optional[List[str]] = None,
    expected_min_rows: int = 1
) -> bool:
    """
    Validates the integrity of a CSV file by checking its columns and minimum number of rows.

    Args:
        file_path (str): Path to the CSV file.
        expected_columns (List[str], optional): List of expected column names. Defaults to None.
        expected_min_rows (int, optional): Minimum number of rows expected. Defaults to 1.

    Returns:
        bool: True if validation passes, False otherwise.
    """
    try:
        logging.debug(f"Validating CSV file: {file_path}")
        df = pd.read_csv(file_path)
        if expected_columns:
            if not all(col in df.columns for col in expected_columns):
                logging.error(f"Validation failed for '{file_path}': Missing expected columns.")
                return False
        if len(df) < expected_min_rows:
            logging.error(f"Validation failed for '{file_path}': Expected at least {expected_min_rows} rows, found {len(df)}.")
            return False
        logging.info(f"Validation passed for '{file_path}'.")
        return True
    except Exception as e:
        logging.error(f"Failed to validate CSV file '{file_path}': {e}", exc_info=True)
        return False


def main() -> None:
    """
    The main function orchestrates the Bycycle analysis process.

    It performs the following steps:
        1. Parses command-line arguments.
        2. Starts the MATLAB engine and loads meta data.
        3. Extracts the log path and configures logging.
        4. Processes each subject/session:
            a. Creates necessary directories.
            b. Loads and processes LFP data from .mat files.
            c. Extracts features and writes region-specific CSVs.
            d. Merges region-specific CSVs into a session-wide CSV, retaining only the latest merged CSV.
    Returns:
        None
    """
    # Set Parameters and Paths
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

    # Argument Parsing
    parser = argparse.ArgumentParser(description='Run Bycycle analysis.')
    parser.add_argument('--csv_path', type=str, required=True, help='Path to the CSV files')
    parser.add_argument('--preProcessedPath', type=str, required=True, help='Path to the preprocessed data')
    parser.add_argument('--meta_data_path', type=str, required=True, help='Path to the meta data file')
    parser.add_argument('--log_file_path', type=str, required=False, default='RunBycycle.log', help='Path to the log file')
    args = parser.parse_args()
    
    csv_path = args.csv_path
    preProcessedPath = args.preProcessedPath
    meta_data_path = args.meta_data_path
    log_file_path = args.log_file_path
    
    # Ensure the log directory exists
    pathlib.Path(log_file_path).mkdir(parents=True, exist_ok=True)
    # Generate log filename with prefix and timestamp
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"PythonLog_{timestamp}.log"
    log_file_path = os.path.join(log_file_path, log_filename)
    setup_logging(log_file_path)

    # Load Meta Data Using MATLAB Engine
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
        
        logging.debug(f"Variables available in MATLAB workspace: {available_vars_list}")
        
        if 'metaDataExt' not in available_vars_list:
            raise KeyError(f"The variable 'metaDataExt' does not exist in the MATLAB workspace. Available variables: {available_vars_list}")
        
        metaDataExt = eng.workspace['metaDataExt']
        logging.info(f"Type of 'metaDataExt' retrieved from MATLAB: {type(metaDataExt)}")
        logging.info("Converting MATLAB struct or dict to Python dictionary...")
        metaDataExt_py = struct2dict(metaDataExt)
        logging.info(f"Type of 'metaDataExt_py' after conversion: {type(metaDataExt_py)}")
        
    except Exception as e:
        logging.error(f"Error loading meta data using MATLAB engine: {e}", exc_info=True)
        try:
            eng.quit()
            logging.info("MATLAB engine stopped due to error.")
        except:
            pass
        exit(1)
    
    # Stop MATLAB Engine
    try:
        eng.quit()
        logging.info("MATLAB engine stopped. Python script is continuing to execute without issue.")
    except Exception as e:
        logging.warning(f"Error while stopping MATLAB engine: {e}", exc_info=True)

    # Extract Included Subjects
    included_subject_ids = metaDataExt_py.get('includedSubjectIDs', None)
    if included_subject_ids is None:
        logging.error("Error: 'includedSubjectIDs' not found in metaDataExt.")
        exit(1)
    
    # Convert included_subject_ids to a list of strings
    if isinstance(included_subject_ids, (list, tuple)):
        sessionIDarr = [str(item) for item in included_subject_ids]
    else:
        sessionIDarr = [str(included_subject_ids)]
    
    logging.info(f"Included Subject IDs: {sessionIDarr}")
    
    # Create directories for each subject/session
    for session_id in sessionIDarr:
        pt_feature_dir = pathlib.Path(csv_path, session_id)
        try:
            pt_feature_dir.mkdir(parents=True, exist_ok=True)
            logging.info(f"Created directory: {pt_feature_dir}")
        except Exception as e:
            logging.error(f"Failed to create directory {pt_feature_dir}: {e}", exc_info=True)
            continue

    # Extract Final Selected Regions
    final_selected_regions = metaDataExt_py.get('finalSelectedRegions', None)
    if final_selected_regions is None:
        logging.error("Error: 'finalSelectedRegions' not found in metaDataExt.")
        exit(1)
    
    # Convert final_selected_regions to a flat list of strings
    if isinstance(final_selected_regions, (list, tuple)):
        final_selected_regions = flatten_regions(final_selected_regions)
    else:
        final_selected_regions = [str(final_selected_regions)]
    
    logging.info(f"Final Selected Regions: {final_selected_regions}")
    
    # Loop Through Each Subject/Session
    for session_id in sessionIDarr:
        logging.info(f"Processing Session: {session_id}")
                
        for region_name in final_selected_regions:
            pt_feature_regional_dir = os.path.join(csv_path, session_id, region_name)
            try:
                pathlib.Path(pt_feature_regional_dir).mkdir(parents=True, exist_ok=True)
                logging.info(f"Created directory for region: {pt_feature_regional_dir}")
            except Exception as e:
                logging.error(f"Failed to create directory {pt_feature_regional_dir}: {e}", exc_info=True)
                continue
        
        # Define the pattern to match files starting with session_id and ending with 'selectedChanSpkRmvl.mat'
        pattern = os.path.join(preProcessedPath, f"{session_id}*selectedChanSpkRmvl.mat")
        logging.debug(f"Searching for .mat files with pattern: {pattern}")
        
        # Use glob to find files that match the pattern
        matching_files = glob.glob(pattern)
        logging.debug(f"Found {len(matching_files)} files matching the pattern.")
        if matching_files:
            mat_file_path = matching_files[0]
            logging.info(f"Found LFP Data from selected brain regions: {mat_file_path}")
        else:
            logging.error(f"No file found for session '{session_id}' ending with 'selectedChanSpkRmvl.mat'. Skipping this session.")
            continue
        
        # Process each region individually within the unified .mat file
        for region_name in final_selected_regions:                 
            try:
                with h5py.File(mat_file_path, 'r') as f_mat:
                    logging.debug(f"Opened .mat file: {mat_file_path}")
                    # Access the 'filteredSubjectData' group
                    if 'filteredSubjectData' not in f_mat:
                        logging.error(f"'filteredSubjectData' group not found in '{mat_file_path}'. Skipping this session.")
                        continue
                    
                    filteredSubjectData = f_mat['filteredSubjectData']
                    
                    # Access labels for the specific region
                    labels_key = f"{region_name}_labels"
                    if labels_key not in filteredSubjectData:
                        logging.warning(f"'{labels_key}' not found in 'filteredSubjectData'. Skipping this region.")
                        continue
                    labels_data = filteredSubjectData[labels_key]
                    logging.debug(f"labels_data shape: {labels_data.shape}")

                    # Adjusted labels extraction to handle different shapes
                    labels = []
                    if len(labels_data.shape) == 1:
                        for i in range(labels_data.shape[0]):
                            label_ref = labels_data[i]
                            label = resolve_reference(f_mat, label_ref)
                            if label is not None:
                                label = label.tobytes().decode('utf-8').strip()
                                labels.append(label)
                            else:
                                labels.append(f"Channel_{i}")
                                logging.warning(f"Label for channel {i} in region '{region_name}' is None. Assigned default label.")
                    elif len(labels_data.shape) == 2:
                        if labels_data.shape[0] == 1:
                            for i in range(labels_data.shape[1]):
                                label_ref = labels_data[0][i]
                                label = resolve_reference(f_mat, label_ref)
                                if label is not None:
                                    label = label.tobytes().decode('utf-8').strip()
                                    labels.append(label)
                                else:
                                    labels.append(f"Channel_{i}")
                                    logging.warning(f"Label for channel {i} in region '{region_name}' is None. Assigned default label.")
                        elif labels_data.shape[1] == 1:
                            for i in range(labels_data.shape[0]):
                                label_ref = labels_data[i][0]
                                label = resolve_reference(f_mat, label_ref)
                                if label is not None:
                                    label = label.tobytes().decode('utf-8').strip()
                                    labels.append(label)
                                else:
                                    labels.append(f"Channel_{i}")
                                    logging.warning(f"Label for channel {i} in region '{region_name}' is None. Assigned default label.")
                        else:
                            logging.error(f"Unexpected labels_data shape: {labels_data.shape}")
                            continue
                    else:
                        logging.error(f"Unexpected labels_data shape: {labels_data.shape}")
                        continue
                    
                    logging.debug(f"Extracted labels: {labels}")
                    
                    # Access LFP data for the specific region
                    lfp_key = f"{region_name}_selectedChanSpkRmvl"
                    if lfp_key not in filteredSubjectData:
                        logging.warning(f"'{lfp_key}' not found in 'filteredSubjectData'. Skipping this region.")
                        continue
                    lfp_data_refs = filteredSubjectData[lfp_key]
                    
                    # Access time data
                    if 'time' not in filteredSubjectData:
                        logging.warning(f"'time' not found in 'filteredSubjectData'. Skipping this region.")
                        continue
                    time_data_refs = filteredSubjectData['time']
                    
                    # Determine the number of trials correctly
                    num_trials = lfp_data_refs.shape[1] if lfp_data_refs.shape[0] == 1 else lfp_data_refs.shape[0]
                    logging.info(f"Number of trials for region '{region_name}': {num_trials}")
                    
                    # Debugging shapes
                    logging.debug(f"lfp_data_refs shape: {lfp_data_refs.shape}")
                    logging.debug(f"time_data_refs shape: {time_data_refs.shape}")
                    
                    trials_extra = []
                    time_all = []
                    
                    # Load LFP data from each trial
                    for i_trial in range(num_trials):
                        try:
                            # Adjust indexing based on data shape
                            if lfp_data_refs.shape[0] == 1:
                                lfp_cell_ref = lfp_data_refs[0][i_trial]
                                time_cell_ref = time_data_refs[0][i_trial]
                            else:
                                lfp_cell_ref = lfp_data_refs[i_trial][0]
                                time_cell_ref = time_data_refs[i_trial][0]
                            lfp_trial_data = resolve_reference(f_mat, lfp_cell_ref)
                            if lfp_trial_data is None:
                                logging.warning(f"LFP data for trial {i_trial} is None. Skipping this trial.")
                                continue
                            lfp_trial_data = np.array(lfp_trial_data).T
                            
                            time_vector = resolve_reference(f_mat, time_cell_ref)
                            if time_vector is None:
                                logging.warning(f"Time data for trial {i_trial} is None. Skipping this trial.")
                                continue
                            time_vector = time_vector.flatten()
                            time_vector = np.array(time_vector).flatten()
                            
                            # Check that lfp_trial_data and time_vector have matching lengths
                            if lfp_trial_data.shape[0] != len(time_vector):
                                logging.warning(f"Mismatch in data length for trial {i_trial}: LFP data has {lfp_trial_data.shape[0]} samples, time vector has {len(time_vector)} samples.")
                                min_length = min(lfp_trial_data.shape[0], len(time_vector))
                                lfp_trial_data = lfp_trial_data[:min_length, :]
                                time_vector = time_vector[:min_length]
                                logging.debug(f"Trimmed LFP and time data for trial {i_trial} to {min_length} samples.")
                            
                            # Ensure data type consistency
                            time_vector = time_vector.astype(np.float64)
                            lfp_trial_data = lfp_trial_data.astype(np.float64)
                            
                            # Create boolean index for the desired time range
                            tidx = np.logical_and(time_vector >= xlim[0], time_vector < xlim[1])
                            
                            # Apply the time index to both time_vector and lfp_trial_data
                            time_vector = time_vector[tidx]
                            lfp_trial_data = lfp_trial_data[tidx, :]
                            
                            logging.debug(f"Trial {i_trial}: Applied time indexing. Remaining samples: {len(time_vector)}")
                            
                            # Check for NaNs or Infinities
                            if np.isnan(lfp_trial_data).any() or np.isinf(lfp_trial_data).any():
                                logging.warning(f"Trial {i_trial} contains NaNs or infinities. Skipping this trial.")
                                continue
                            
                            trials_extra.append(lfp_trial_data)
                            time_all.append(time_vector)
                            
                            logging.info(f"Trial {i_trial} - time_vector shape: {time_vector.shape}, lfp_trial_data shape: {lfp_trial_data.shape}")
                            
                        except Exception as e:
                            logging.error(f"Error processing trial {i_trial}: {e}", exc_info=True)
                            continue
                    
                    if not trials_extra:
                        logging.warning(f"No valid trials found for region '{region_name}' in session '{session_id}'. Skipping.")
                        continue
                    
                    # Get all combinations of trials and channels
                    tuples = []
                    num_channels = lfp_trial_data.shape[1]  # Number of channels based on LFP data
                    logging.debug(f"Number of channels based on lfp_trial_data: {num_channels}")
                    # Ensure labels length matches num_channels
                    if len(labels) != num_channels:
                        logging.warning(f"Number of labels ({len(labels)}) does not match number of channels ({num_channels}). Adjusting labels.")
                        labels = labels[:num_channels]
                    for i_trial in range(len(trials_extra)):
                        for j_channel in range(num_channels):
                            tuples.append([i_trial, j_channel])
                    
                    logging.debug(f"Total number of trial-channel combinations: {len(tuples)}")
                    
                    # Get features dataframes for all trials and channels for this region
                    try:
                        dataframes = get_df(
                            trials_extra,
                            tuples,
                            threshold_kwargs=m_threshold_kwargs,
                            fs=fs,
                            f_lowpass=f_lowpass,
                            f_theta=f_theta
                        )
                    except Exception as e:
                        logging.error(f"Error during feature extraction for session {session_id}, region {region_name}: {e}", exc_info=True)
                        continue
                    
                    # Generate a timestamp for filenames (single timestamp per session)
                    session_timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
                    
                    # Define the path for the region-specific CSV within the brain region directory
                    region_csv_path = os.path.join(
                        csv_path, session_id, region_name,
                        f"{session_id}_{region_name}_bycycle_features_{session_timestamp}.csv"
                    )
                    
                    logging.debug(f"Preparing to write region-specific CSV: {region_csv_path}")
                    
                    # Open the region-specific CSV file in write mode
                    try:
                        with open(region_csv_path, 'w', newline='') as region_csv_file:
                            header_written = False  # To write header only once
                            
                            # Append trial, channel index, and channel label info to each features dataframe and write to region CSV
                            for i_df, tuple_info in enumerate(tuples):
                                try:
                                    df = dataframes[i_df]
                                    if df is not None and not df.empty:
                                        df = df.copy()
                                        trial_num = tuple_info[0]
                                        channel_idx = tuple_info[1]
                                        channel_label = labels[channel_idx]
                                        df.insert(0, 'trial', trial_num)
                                        df.insert(1, 'channel_idx', channel_idx)
                                        df.insert(2, 'channel_label', channel_label)
                                        
                                        # Write to region-specific CSV
                                        df.to_csv(region_csv_file, header=not header_written, index=False, mode='a')
                                        if not header_written:
                                            header_written = True
                                        
                                        logging.debug(f"Appended trial {trial_num}, channel {channel_idx} to region-specific CSV.")
                                    else:
                                        logging.warning(f"No data for dataframe index {i_df}.")
                                except Exception as e:
                                    logging.warning(f"Failed to insert trial/channel info for dataframe index {i_df}: {e}", exc_info=True)
                                    continue
                        
                        logging.info(f"Region-specific CSV file created: {region_csv_path}")
                        
                        # Validate the created CSV file
                        min_expected_columns = 3  # 'trial', 'channel_idx', 'channel_label'
                        is_valid = validate_csv(file_path=region_csv_path, expected_min_rows=1)
                        if not is_valid:
                            logging.error(f"Validation failed for region-specific CSV file: {region_csv_path}")
                        else:
                            logging.info(f"Validation passed for region-specific CSV file: {region_csv_path}")
                            
                    except Exception as e:
                        logging.error(f"Failed to write region-specific CSV file '{region_csv_path}': {e}", exc_info=True)
                        continue
            except Exception as e:
                logging.error("Failed to load LFP data. Bycycle feature extraction failed.", exc_info=True)
                continue        

            # After processing all regions within the session, concatenate the region-specific CSVs into a merged CSV within the session directory
            try:
                session_dir = os.path.join(csv_path, session_id)
                merged_csv_path = os.path.join(
                    session_dir,
                    f"{session_id}_merged_bycycle_features_{session_timestamp}.csv"
                )
                
                # Direct File-Based Concatenation
                region_csv_pattern = os.path.join(session_dir, "**", "*_bycycle_features_*.csv")
                logging.debug(f"Searching for region-specific CSV files with pattern: {region_csv_pattern}")
                region_csv_files = glob.glob(region_csv_pattern, recursive=True)
                logging.debug(f"Found {len(region_csv_files)} region-specific CSV files for merging.")
                
                if region_csv_files:
                    logging.info(f"Starting concatenation of region-specific CSV files for session '{session_id}'.")
                    # Open the merged CSV file for writing
                    with open(merged_csv_path, 'w', newline='') as merged_csv_file:
                        header_written = False
                        for region_csv in region_csv_files:
                            try:
                                with open(region_csv, 'r') as rc_file:
                                    for idx_line, line in enumerate(rc_file):
                                        if idx_line == 0:
                                            if not header_written:
                                                merged_csv_file.write(line)
                                                header_written = True
                                                logging.debug(f"Wrote header from '{region_csv}' to merged CSV.")
                                            else:
                                                logging.debug(f"Skipped header from '{region_csv}'.")
                                                continue
                                        else:
                                            merged_csv_file.write(line)
                            except Exception as e:
                                logging.error(f"Failed to read region-specific CSV file '{region_csv}': {e}", exc_info=True)
                                continue
                    logging.info(f"Merged CSV file created at: {merged_csv_path}")
                    
                    # Validate the merged CSV file
                    is_valid_merged = validate_csv(file_path=merged_csv_path, expected_min_rows=1)
                    if not is_valid_merged:
                        logging.error(f"Validation failed for merged CSV file: {merged_csv_path}")
                    else:
                        logging.info(f"Validation passed for merged CSV file: {merged_csv_path}")

                    # Delete older merged CSVs, retaining only the latest one
                    merged_pattern = os.path.join(session_dir, f"{session_id}_merged_bycycle_features_*.csv")
                    merged_files = glob.glob(merged_pattern)
                    logging.debug(f"Found {len(merged_files)} merged CSV files for session '{session_id}'.")
                    
                    # Sort the merged files by timestamp in filename
                    def extract_timestamp(file_path: str) -> Optional[datetime]:
                        match = re.search(r'_merged_bycycle_features_(\d{8}_\d{6})\.csv$', file_path)
                        if match:
                            try:
                                return datetime.strptime(match.group(1), "%Y%m%d_%H%M%S")
                            except ValueError:
                                return None
                        return None
                    
                    merged_files_with_timestamps = [(file, extract_timestamp(file)) for file in merged_files]
                    # Filter out files where timestamp extraction failed
                    merged_files_with_timestamps = [(file, ts) for file, ts in merged_files_with_timestamps if ts is not None]
                    # Sort by timestamp descending
                    merged_files_with_timestamps.sort(key=lambda x: x[1], reverse=True)
                    
                    if len(merged_files_with_timestamps) > 1:
                        # Keep the latest merged CSV, delete the rest
                        latest_file, latest_ts = merged_files_with_timestamps[0]
                        files_to_delete = [file for file, ts in merged_files_with_timestamps[1:]]
                        for file in files_to_delete:
                            try:
                                os.remove(file)
                                logging.info(f"Deleted older merged CSV file: {file}")
                            except Exception as e:
                                logging.error(f"Failed to delete older merged CSV file '{file}': {e}", exc_info=True)
                    else:
                        logging.debug(f"No older merged CSV files to delete for session '{session_id}'.")
                else:
                    logging.warning(f"No region-specific CSV files found for session '{session_id}'. Merged CSV not created.")
            except Exception as e:
                logging.error(f"Failed to concatenate region-specific CSV files for session '{session_id}': {e}", exc_info=True)
                continue


if __name__ == "__main__":
    """
    Entry point of the script.

    It initializes the overall execution timer, runs the main function, and logs the total execution time.
    """
    # Start the overall timer
    overall_start_time = time.time()
    
    try:
        main()
    except Exception as e:
        logging.error(f"An unexpected error occurred during script execution: {e}", exc_info=True)
    finally:
        # End the overall timer and log the execution time
        overall_end_time = time.time()
        total_time = overall_end_time - overall_start_time
        hours, rem = divmod(total_time, 3600)
        minutes, seconds = divmod(rem, 60)
        logging.info(f"Script execution completed in {int(hours)}h {int(minutes)}m {int(seconds)}s.")
