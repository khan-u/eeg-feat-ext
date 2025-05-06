function verifyRawDataFiles(selectedSubjectIDs, projectPaths, logFilePath)
    % VERIFYRAWDATAFILES Verifies and moves raw data files to the correct directory.
    %
    % Inputs:
    %   selectedSubjectIDs - (cell array of strings) IDs of selected subjects.
    %   projectPaths       - (struct) Contains paths used in the project.
    %       .basePath      - Base directory where raw data files are located.
    %       .rawDataPath   - Destination directory for raw data files.
    %   logFilePath        - (string) Path to the log file.
    %
    % Outputs:
    %   None. Moves files and logs operations.

    %% Configuration and Setup
    requiredSuffixes = ["_allChanSpkRmvl.mat", "_highAmp4_highDiff10.mat", ...
                        "_highAmp4_highDiff10_corr.mat", "_suaInfo.mat"];
    
    % Ensure the raw directory exists
    rawDir = ensureDirectory(projectPaths.rawDataPath, logFilePath);
    
    % Find all .mat files in the base directory and its subdirectories
    allMatFiles = dir(fullfile(projectPaths.basePath, '**', '*.mat'));
    
    % Use containers.Map to track subject files (without duplicate checks)
    subjectFiles = containers.Map('KeyType', 'char', 'ValueType', 'char');  % Explicitly set KeyType and ValueType
    
    %% Process Files - Track and Store Unique Files
    for file = allMatFiles'
        % Skip files already in the raw directory
        if contains(fullfile(file.folder, file.name), rawDir)
            continue;
        end

        % Extract subject ID and suffix
        [subjectID, suffix] = extractSubjectID(file.name, requiredSuffixes);
        if isempty(subjectID) || isempty(suffix)
            % Skip files that do not match the required pattern
            continue;
        end

        % Create a unique key based on subjectID and suffix
        key = strcat(subjectID, suffix);

        % Store the file path in the map
        subjectFiles(key) = fullfile(file.folder, file.name);
    end

    %% Move All Unique Files to Raw Directory
    moveAllFilesToRaw(subjectFiles, rawDir, logFilePath);

    %% Verify Missing Files After Moving
    verifyMissingFiles(selectedSubjectIDs, requiredSuffixes, rawDir, logFilePath);

    % Log completion message
    logMessage('All operations completed successfully.', logFilePath, 'INFO');
end

function rawDir = ensureDirectory(path, logFilePath)
    % ENSUREDIRECTORY Ensures that a directory exists; creates it if it doesn't.
    %
    % Inputs:
    %   path        - (string) Path to the directory.
    %   logFilePath - (string) Path to the log file.
    %
    % Outputs:
    %   rawDir      - (string) The ensured directory path.

    if ~isfolder(path)
        try
            mkdir(path);
            logMessage(['Created directory: ' path], logFilePath, 'INFO');
        catch ME
            logMessage(['Failed to create directory: ' ME.message], logFilePath, 'ERROR');
            error(['Failed to create directory: ' ME.message]);
        end
    else
        logMessage(['Directory already exists: ' path], logFilePath, 'INFO');
    end
    rawDir = path;
end

function [subjectID, suffix] = extractSubjectID(fileName, requiredSuffixes)
    % EXTRACTPATIENTID Extracts subject ID and suffix from a file name if it matches the required format.
    %
    % Inputs:
    %   fileName          - (string) Name of the file.
    %   requiredSuffixes  - (string array) List of required suffixes.
    %
    % Outputs:
    %   subjectID - (string) Extracted subject ID (e.g., 'P60cs'). Empty if not matched.
    %   suffix    - (string) Extracted suffix. Empty if not matched.

    % Find suffix that matches the end of the fileName
    suffixMatch = requiredSuffixes(endsWith(fileName, requiredSuffixes));
    if isempty(suffixMatch)
        subjectID = [];
        suffix = [];
        return;
    else
        suffix = suffixMatch(1);
    end

    % Extract subject ID using regex (e.g., 'P60cs' from 'P60cs_highAmp4_highDiff10.mat')
    subjectIDMatch = regexp(fileName, '^(P\d+cs)', 'match', 'once');
    if isempty(subjectIDMatch)
        subjectID = [];
    else
        subjectID = subjectIDMatch;
    end
end

function moveAllFilesToRaw(subjectFiles, rawDir, logFilePath)
    % MOVEALLFILESTORAW Moves all unique files to the raw directory.
    %
    % Inputs:
    %   subjectFiles - (containers.Map) Map containing file paths to move.
    %   rawDir       - (string) Destination directory.
    %   logFilePath  - (string) Path to the log file.
    %
    % Outputs:
    %   None. Moves files and logs operations.

    keys = subjectFiles.keys;
    numFiles = numel(keys);
    logMessage(['Starting to move ' num2str(numFiles) ' files to raw directory.'], logFilePath, 'INFO');

    for i = 1:numFiles
        src = subjectFiles(keys{i});
        [~, fileName, ext] = fileparts(src);
        dest = fullfile(rawDir, [fileName, ext]);

        try
            movefile(src, dest);
            logMessage(['Moved: ' dest], logFilePath, 'INFO');
        catch ME
            logMessage(['Failed to move: ' src ' to ' dest '. Error: ' ME.message], logFilePath, 'ERROR');
            error(['Failed to move: ' src ' to ' dest '. Error: ' ME.message]);
        end
    end
end

function verifyMissingFiles(selectedSubjectIDs, requiredSuffixes, rawDir, logFilePath)
    % VERIFYMISSINGFILES Checks if all required files are present in the raw directory.
    %
    % Inputs:
    %   selectedSubjectIDs - (cell array of strings) IDs of selected subjects.
    %   requiredSuffixes   - (string array) List of required suffixes.
    %   rawDir             - (string) Directory to verify.
    %   logFilePath        - (string) Path to the log file.
    %
    % Outputs:
    %   None. Logs missing files and raises an error if any are missing.

    missingFiles = {};

    for i = 1:numel(selectedSubjectIDs)
        subjectID = selectedSubjectIDs{i};
        for j = 1:numel(requiredSuffixes)
            suffix = requiredSuffixes(j);
            filePath = fullfile(rawDir, strcat(subjectID, suffix));

            if ~isfile(filePath)
                missingFiles{end+1} = filePath; %#ok<AGROW>
                logMessage(['Missing file: ' filePath], logFilePath, 'ERROR');
            end
        end
    end

    if ~isempty(missingFiles)
        missingList = strjoin(missingFiles, '\n');
        error(['Missing required files:\n' missingList]);
    else
        logMessage('All required files are present in the raw directory.', logFilePath, 'INFO');
    end
end
