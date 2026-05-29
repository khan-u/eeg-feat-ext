function recycleMetaData(paths, logFilePath)
    % Moves the original metaData.mat from the data directory to the recycle directory.
    %
    % Inputs:
    %   paths       - (struct) Project paths structure.
    %   logFilePath - (string) Path to the log file.

    originalMetaDataPath = fullfile(paths.dataPath, 'metaData.mat');
    targetPath           = fullfile(paths.recyclePath, 'metaData.mat');

    if isfile(originalMetaDataPath)
        if isfile(targetPath)
            logMessage(sprintf('metaData.mat already exists in recycle directory: %s. Skipping to prevent overwrite.', paths.recyclePath), logFilePath, 'WARNING');
        else
            try
                movefile(originalMetaDataPath, paths.recyclePath);
                logMessage(sprintf('Moved original metaData.mat to recycle directory: %s', paths.recyclePath), logFilePath, 'INFO');
            catch ME
                logMessage(sprintf('Error moving metaData.mat to recycle directory: %s', ME.message), logFilePath, 'ERROR');
            end
        end
    else
        logMessage(sprintf('Original metaData.mat not found at: %s. No action taken.', originalMetaDataPath), logFilePath, 'WARNING');
    end
end
