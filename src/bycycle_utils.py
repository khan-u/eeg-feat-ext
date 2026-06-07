"""
Pure utility functions for the bycycle feature extraction pipeline.
No side effects, no I/O — importable and testable in isolation.
"""

import os
import logging
import pandas as pd
from typing import Any, List, Optional


def struct2dict(s: Any) -> Any:
    """Recursively converts a MATLAB struct or list to a Python dictionary."""
    if isinstance(s, dict):
        return {k: struct2dict(v) for k, v in s.items()}
    elif isinstance(s, list):
        return [struct2dict(item) for item in s]
    else:
        return s


def flatten_regions(regions: Any) -> List[str]:
    """Flattens a nested list of region names into a flat list of strings."""
    flat_list = []
    for item in regions:
        if isinstance(item, (list, tuple)):
            flat_list.extend(flatten_regions(item))
        else:
            flat_list.append(str(item))
    return flat_list


def validate_csv(
    file_path: str,
    expected_columns: Optional[List[str]] = None,
    expected_min_rows: int = 1
) -> bool:
    """
    Validates a CSV file for expected columns and minimum row count.

    Returns True if validation passes, False otherwise.
    """
    try:
        logging.debug(f"Validating CSV file: {file_path}")
        df = pd.read_csv(file_path)
        if expected_columns:
            if not all(col in df.columns for col in expected_columns):
                logging.error(f"Validation failed for '{file_path}': Missing expected columns.")
                return False
        if len(df) < expected_min_rows:
            logging.error(
                f"Validation failed for '{file_path}': "
                f"Expected at least {expected_min_rows} rows, found {len(df)}."
            )
            return False
        logging.info(f"Validation passed for '{file_path}'.")
        return True
    except Exception as e:
        logging.error(f"Failed to validate CSV file '{file_path}': {e}", exc_info=True)
        return False
