import os
import sys
import tempfile

import pandas as pd
import pytest

sys.path.insert(0, os.path.join(os.path.dirname(__file__), ".."))
from bycycle_utils import struct2dict, flatten_regions, validate_csv


def test_struct2dict_nested():
    inp = {"a": {"b": 1}, "c": [2, 3]}
    result = struct2dict(inp)
    assert result == {"a": {"b": 1}, "c": [2, 3]}


def test_struct2dict_scalar():
    assert struct2dict(42) == 42
    assert struct2dict("hello") == "hello"


def test_flatten_regions_flat():
    assert flatten_regions(["HP", "A", "SMA"]) == ["HP", "A", "SMA"]


def test_flatten_regions_nested():
    assert flatten_regions([["HP", "A"], "SMA"]) == ["HP", "A", "SMA"]


def test_validate_csv_passes(tmp_path):
    csv_file = tmp_path / "test.csv"
    df = pd.DataFrame({"trial": [0, 1], "channel_idx": [0, 0], "val": [1.0, 2.0]})
    df.to_csv(csv_file, index=False)
    assert validate_csv(str(csv_file), expected_columns=["trial", "channel_idx"], expected_min_rows=1)


def test_validate_csv_missing_column(tmp_path):
    csv_file = tmp_path / "test.csv"
    df = pd.DataFrame({"trial": [0]})
    df.to_csv(csv_file, index=False)
    assert not validate_csv(str(csv_file), expected_columns=["trial", "missing_col"])
