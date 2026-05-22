function verifyRawDataFiles(selectedSubjectIDs, projectPaths, logFilePath)
    % Finds raw subject .mat files anywhere in the project, moves them to
    % data/raw/, and confirms all required files are present.
    %
    % Inputs:
    %   selectedSubjectIDs - (string array) IDs of selected subjects.
    %   projectPaths       - (struct) Project paths structure.
    %   logFilePath        - (string) Path to the log file.

    requiredSuffixes = ["_allChanSpkRmvl.mat", "_highAmp4_highDiff10.mat", ...
                        "_highAmp4_highDiff10_corr.mat", "_suaInfo.mat"];

    rawDir = ensureDirectory(projectPaths.rawDataPath, logFilePath);

    allMatFiles = dir(fullfile(projectPaths.basePath, '**', '*.mat'));

    subjectFiles = containers.Map('KeyType', 'char', 'ValueType', 'char');

    for file = allMatFiles'
        if contains(fullfile(file.folder, file.name), rawDir)
            continue;
        end

        [subjectID, suffix] = extractSubjectID(file.name, requiredSuffixes);
        if isempty(subjectID) || isempty(suffix)
            continue;
        end

        key = strcat(subjectID, suffix);
        subjectFiles(key) = fullfile(file.folder, file.name);
    end

    moveAllFilesToRaw(subjectFiles, rawDir, logFilePath);
    verifyMissingFiles(selectedSubjectIDs, requiredSuffixes, rawDir, logFilePath);

    logMessage('All operations completed successfully.', logFilePath, 'INFO');
end

function rawDir = ensureDirectory(path, logFilePath)
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
    suffixMatch = requiredSuffixes(endsWith(fileName, requiredSuffixes));
    if isempty(suffixMatch)
        subjectID = [];
        suffix = [];
        return;
    else
        suffix = suffixMatch(1);
    end

    subjectIDMatch = regexp(fileName, '^(P\d+cs)', 'match', 'once');
    if isempty(subjectIDMatch)
        subjectID = [];
    else
        subjectID = subjectIDMatch;
    end
end

function moveAllFilesToRaw(subjectFiles, rawDir, logFilePath)
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
