function verifyAndMoveFiles(paths, logFilePath)
    % Verifies required project files are in the correct directories and relocates any that are not.
    %
    % Inputs:
    %   paths       - (struct) Project paths structure.
    %   logFilePath - (string) Path to the log file.

    requiredFiles = {
        'MAIN.m',                       paths.basePath;
        'requirements.txt',             paths.basePath;
        'call_python_bycycle.m',        paths.codePath;
        'definePaths.m',                paths.codePath;
        'logMessage.m',                 paths.codePath;
        'defineStCATsessions.m',        paths.codePath;
        'defineTrialsStCat.m',          paths.codePath;
        'extractLFP.m',                 paths.codePath;
        'filterSubjectsLFP.m',          paths.codePath;
        'loadMetaData.m',               paths.codePath;
        'processSubjects.m',            paths.codePath;
        'recycleMetaData.m',            paths.codePath;
        'RunBycycle.py',                paths.codePath;
        'saveExtendedMetadata.m',       paths.codePath;
        'selectSubjectsAndRegions.m',   paths.codePath;
        'setupLogging.m',               paths.codePath;
        'trialinfoSternbergCAT.m',      paths.codePath;
        'createDirectories.m',          paths.codePath;
        'checkMetaDataFile.m',          paths.codePath;
        'setupProject.m',               paths.codePath;
        'verifyRawDataFiles.m',         paths.codePath;
        'compareVersions.m',            paths.codePath;
        'verifyAndMoveFiles.m',         paths.codePath;
        'saveFolderTree.m',             paths.codePath;
    };

    fileNames   = requiredFiles(:,1);
    correctDirs = requiredFiles(:,2);

    for i = 1:length(fileNames)
        fileName   = fileNames{i};
        correctDir = correctDirs{i};
        correctPath = fullfile(correctDir, fileName);

        if isfile(correctPath)
            logMessage(['File already in correct directory: ' correctPath], logFilePath, 'INFO');
            continue;
        end

        foundPath = findFileInProject(paths.basePath, fileName);

        if ~isempty(foundPath)
            if any(strcmp(fileName, {'MAIN.m', 'logMessage.m', 'requirements.txt'}))
                if ~strcmpi(fileparts(foundPath), paths.basePath)
                    try
                        movefile(foundPath, paths.basePath);
                        logMessage(['Moved ' fileName ' to ' paths.basePath], logFilePath, 'INFO');
                    catch ME
                        logMessage(['Failed to move ' fileName ': ' ME.message], logFilePath, 'ERROR');
                        error(['Failed to move ' fileName ': ' ME.message]);
                    end
                else
                    logMessage(['File correctly located in basePath: ' foundPath], logFilePath, 'INFO');
                end
            else
                if ~strcmpi(fileparts(foundPath), correctDir)
                    try
                        movefile(foundPath, correctDir);
                        logMessage(['Moved ' fileName ' to ' correctDir], logFilePath, 'INFO');
                    catch ME
                        logMessage(['Failed to move ' fileName ': ' ME.message], logFilePath, 'ERROR');
                        error(['Failed to move ' fileName ': ' ME.message]);
                    end
                else
                    logMessage(['File correctly located in ' correctDir ': ' correctPath], logFilePath, 'INFO');
                end
            end
        else
            logMessage(['Missing required file: ' fileName], logFilePath, 'ERROR');
            error(['Missing required file: ' fileName]);
        end
    end

    try
        addpath(genpath(paths.codePath));
        logMessage('Added src directory to MATLAB path.', logFilePath, 'INFO');
        if any(strcmpi(paths.codePath, strsplit(path, pathsep))) || contains(path, paths.codePath)
            logMessage('src directory successfully added to MATLAB path.', logFilePath, 'INFO');
        else
            logMessage('src directory was not added to MATLAB path as expected.', logFilePath, 'ERROR');
            error('Failed to add src directory to MATLAB path.');
        end
    catch ME
        logMessage(['Failed to add src directory to MATLAB path: ' ME.message], logFilePath, 'ERROR');
        error(['Failed to add src directory to MATLAB path: ' ME.message]);
    end
end

function foundPath = findFileInProject(baseDir, fileName)
    foundPath = '';
    files = dir(fullfile(baseDir, '**', fileName));
    if ~isempty(files)
        foundPath = fullfile(files(1).folder, files(1).name);
    end
end
