function checkMetaDataFile(projectPaths, logFilePath)
    % Verifies the presence of metaData.mat and moves it to the data directory if needed.
    %
    % Inputs:
    %   projectPaths - (struct) Structure containing project paths.
    %   logFilePath  - (string) Path to the log file.

    basePath = projectPaths.basePath;
    dataPath = projectPaths.dataPath;

    metaDataFiles = dir(fullfile(basePath, '**', 'metaData.mat'));

    if isempty(metaDataFiles)
        logMessage('metaData.mat not found in the project.', logFilePath, 'ERROR');
        error('metaData.mat is missing from the project.');
    elseif numel(metaDataFiles) > 1
        logMessage('Duplicate metaData.mat files found.', logFilePath, 'ERROR');
        error('Duplicate metaData.mat files detected. Please ensure only one copy exists.');
    else
        metaDataLocation = fullfile(metaDataFiles(1).folder, metaDataFiles(1).name);
        correctLocation  = fullfile(dataPath, 'metaData.mat');

        if ~strcmp(metaDataLocation, correctLocation)
            movefile(metaDataLocation, correctLocation);
            logMessage('metaData.mat moved to the correct location.', logFilePath, 'INFO');
        else
            logMessage('metaData.mat is already in the correct location.', logFilePath, 'INFO');
        end
    end
end
