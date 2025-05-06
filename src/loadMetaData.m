function metaData = loadMetaData(paths, logFilePath)
    % LOADMETADATA Loads session metadata from 'metaData.mat'.
    %
    % Syntax:
    %   metaData = loadMetaData(paths, logFilePath)
    %
    % Description:
    %   Loads the metadata file containing session IDs and other relevant information.
    %   Validates the presence of necessary fields and logs the status.
    %
    % Inputs:
    %   paths - (struct) A structure containing directory paths as defined by definePaths().
    %   logFilePath - (string) Path to the log file for recording metadata loading status.
    %
    % Outputs:
    %   metaData - A structure containing metadata loaded from 'metaData.mat'.
    %
    % Example:
    %   metaData = loadMetaData(paths, '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage
    
    % Define the path to metaData.mat
    metaDataPath = fullfile(paths.dataPath, 'metaData.mat');
    
    % Attempt to load metaData.mat
    try
        metaData = load(metaDataPath);
        if ~isfield(metaData, 'sessionID')
            error('metaData.mat does not contain "sessionID" field.');
        end
        if isempty(metaData.sessionID)
            error('"sessionID" field in metaData.mat is empty.');
        end
        totalSubjects = length(metaData.sessionID);
        logMessage(sprintf('Loaded %d session(s) from metadata.', totalSubjects), logFilePath, 'INFO');
    catch ME
        logMessage(sprintf('Failed to load metaData.mat: %s', ME.message), logFilePath, 'ERROR');
        error('Terminating script due to failed metadata loading.');
    end
end
