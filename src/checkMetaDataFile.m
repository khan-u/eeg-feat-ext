function checkMetaDataFile(projectPaths, logFilePath)
    % CHECKMETADATAFILE Verifies the presence of metaData.mat and checks for duplicates.
    %
    % Inputs:
    %   projectPaths - (struct) Structure containing project paths.
    %   logFilePath  - (string) Path to the log file for logging messages.
    %
    % Throws:
    %   Error if duplicate metaData.mat files are found or if the file is missing.

    % Extract the base and data paths from projectPaths
    basePath = projectPaths.basePath;
    dataPath = projectPaths.dataPath;

    % Find all occurrences of metaData.mat in the project directory
    metaDataFiles = dir(fullfile(basePath, '**', 'metaData.mat'));

    if isempty(metaDataFiles)
        logMessage('metaData.mat not found in the project.', logFilePath, 'ERROR');
        error('metaData.mat is missing from the project.');
    elseif numel(metaDataFiles) > 1
        logMessage('Duplicate metaData.mat files found.', logFilePath, 'ERROR');
        error('Duplicate metaData.mat files detected. Please ensure only one copy exists.');
    else
        % If a single metaData.mat exists, check its location
        metaDataLocation = fullfile(metaDataFiles(1).folder, metaDataFiles(1).name);
        correctLocation = fullfile(dataPath, 'metaData.mat');

        if ~strcmp(metaDataLocation, correctLocation)
            % Move the file to the correct location
            movefile(metaDataLocation, correctLocation);
            logMessage('metaData.mat moved to the correct location.', logFilePath, 'INFO');
        else
            logMessage('metaData.mat is already in the correct location.', logFilePath, 'INFO');
        end
    end
end
