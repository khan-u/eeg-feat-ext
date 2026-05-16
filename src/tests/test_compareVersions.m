% Unit tests for compareVersions
% Run from the src/ directory with: run('tests/test_compareVersions.m')

addpath(fileparts(mfilename('fullpath')) + "/..");

assert(compareVersions('1.0.0', '0.9.9') == 1,  'v1 > v2 should return 1');
assert(compareVersions('0.9.9', '1.0.0') == -1, 'v1 < v2 should return -1');
assert(compareVersions('1.0.0', '1.0.0') == 0,  'equal versions should return 0');

disp('compareVersions: all tests passed');
