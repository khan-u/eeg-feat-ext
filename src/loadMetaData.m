function metaData = loadMetaData(paths, logFilePath)
    % Loads session metadata from metaData.mat and validates required fields.
    %
    % Inputs:
    %   paths       - (struct) Structure containing directory paths.
    %   logFilePath - (string) Path to the log file.
    %
    % Outputs:
    %   metaData - Struct loaded from metaData.mat.

    metaDataPath = fullfile(paths.dataPath, 'metaData.mat');

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
