function recycleMetaData(paths, logFilePath)
    % RECYCLEMETADATA Moves the original metaData.mat to the recycle directory.
    %
    % Syntax:
    %   recycleMetaData(paths, logFilePath)
    %
    % Description:
    %   Transfers the original 'metaData.mat' file from the base directory to the recycle directory
    %   to maintain a backup. Ensures that the recycle directory does not overwrite existing files.
    %   Logs the status of the move operation.
    %
    % Inputs:
    %   paths - (struct) A structure containing directory paths as defined by definePaths().
    %   logFilePath - (string) Path to the log file for recording metadata recycling status.
    %
    % Outputs:
    %   None (the function moves files).
    %
    % Example:
    %   recycleMetaData(paths, '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage
    
    % Define the original metaData.mat file path
    originalMetaDataPath = fullfile(paths.dataPath, 'metaData.mat');
    
    % Define the target path in the recycle directory
    targetPath = fullfile(paths.recyclePath, 'metaData.mat');
    
    % Check if metaData.mat exists before attempting to move
    if isfile(originalMetaDataPath)
        if isfile(targetPath)
            logMessage(sprintf('metaData.mat already exists in recycle directory: %s. Skipping move to prevent overwrite.', paths.recyclePath), logFilePath, 'WARNING');
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
