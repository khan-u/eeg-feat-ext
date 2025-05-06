function verifyAndMoveFiles(paths, logFilePath)
    % VERIFYANDMOVEFILES Verifies the location of each required file and moves it to the correct directory if necessary.
    %
    % Inputs:
    %   paths - (struct) Project paths structure.
    %   logFilePath - (string) Path to the log file.
    %
    % Outputs:
    %   None. Moves files as necessary and logs actions.

    % Define required files and their correct directories
    requiredFiles = {
        % Root directory files (should remain in basePath)
        'MAIN.m', paths.basePath;
        'requirements.txt', paths.basePath;
        
        % Src directory files
        'call_python_bycycle.m', paths.codePath;
        'closest.mexw64', paths.codePath;
        'definePaths.m', paths.codePath;
        'logMessage.m', paths.codePath;
        'defineStCATsessions.m', paths.codePath;
        'defineTrialsStCat.m', paths.codePath;
        'extractLFP.m', paths.codePath;
        'extractMatFilesToText.m', paths.codePath;
        'filterSubjectsLFP.m', paths.codePath;
        'loadMetaData.m', paths.codePath;
        'processSubjects.m', paths.codePath;
        'recycleMetaData.m', paths.codePath;
        'RunBycycle.py', paths.codePath;
        'saveExtendedMetadata.m', paths.codePath;
        'selectSubjectsAndRegions.m', paths.codePath;
        'setupLogging.m', paths.codePath;
        'trialinfoSternbergCAT.m', paths.codePath;
        'createDirectories.m', paths.codePath;
        'checkMetaDataFile.m', paths.codePath;
        'setupProject.m', paths.codePath;
        'verifyRawDataFiles.m', paths.codePath;
        'compareVersions.m', paths.codePath;
        'verifyAndMoveFiles.m', paths.codePath;
        'saveFolderTree.m', paths.codePath;  
        'logMessage.m', paths.codePath;
    };

    % Get a list of all required files
    fileNames = requiredFiles(:,1);
    correctDirs = requiredFiles(:,2);

    % Iterate through each required file
    for i = 1:length(fileNames)
        fileName = fileNames{i};
        correctDir = correctDirs{i};
        correctPath = fullfile(correctDir, fileName);

        % Check if the file already exists in the correct directory
        if isfile(correctPath)
            logMessage(['File already in correct directory: ' correctPath], logFilePath, 'INFO');
            continue;
        end

        % Search for the file in the entire project directory
        foundPath = findFileInProject(paths.basePath, fileName);

        if ~isempty(foundPath)
            % Handle root directory files
            if any(strcmp(fileName, {'MAIN.m', 'logMessage.m', 'requirements.txt'}))
                % These files should remain in the basePath
                if ~strcmpi(fileparts(foundPath), paths.basePath)
                    try
                        movefile(foundPath, paths.basePath);
                        logMessage(['Moved ' fileName ' to ' paths.basePath], logFilePath, 'INFO');
                    catch ME
                        logMessage(['Failed to move ' fileName ' to ' paths.basePath ': ' ME.message], logFilePath, 'ERROR');
                        error(['Failed to move ' fileName ' to ' paths.basePath ': ' ME.message]);
                    end
                else
                    % Already in basePath
                    logMessage(['File correctly located in basePath: ' foundPath], logFilePath, 'INFO');
                end
            else
                % For other files, ensure they are in the correct directory
                if ~strcmpi(fileparts(foundPath), correctDir)
                    try
                        movefile(foundPath, correctDir);
                        logMessage(['Moved ' fileName ' to ' correctDir], logFilePath, 'INFO');
                    catch ME
                        logMessage(['Failed to move ' fileName ' to ' correctDir ': ' ME.message], logFilePath, 'ERROR');
                        error(['Failed to move ' fileName ' to ' correctDir ': ' ME.message]);
                    end
                else
                    % Already in correct directory
                    logMessage(['File correctly located in ' correctDir ': ' correctPath], logFilePath, 'INFO');
                end
            end
        else
            % File not found
            logMessage(['Missing required file: ' fileName], logFilePath, 'ERROR');
            error(['Missing required file: ' fileName]);
        end
    end

    % Add the 'src' directory to MATLAB's search path for future runs
    try
        addpath(genpath(paths.codePath));
        logMessage('Added src directory and its subdirectories to MATLAB path.', logFilePath, 'INFO');

        % Verify that the path was added successfully
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
    % FINDFILEINPROJECT Searches for a file within the project directory and its subdirectories.
    %
    % Inputs:
    %   baseDir - (string) The base directory to start the search.
    %   fileName - (string) The name of the file to search for.
    %
    % Outputs:
    %   foundPath - (string) The full path to the found file. Empty if not found.

    foundPath = '';
    files = dir(fullfile(baseDir, '**', fileName));
    if ~isempty(files)
        % Return the first match
        foundPath = fullfile(files(1).folder, files(1).name);
    end
end
