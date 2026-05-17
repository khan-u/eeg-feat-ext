function createDirectories(projectPaths, logFilePath)
    % Ensures all required project directories exist, creating any that are missing.
    %
    % Inputs:
    %   projectPaths - (struct) Structure containing directory paths.
    %   logFilePath  - (string) Path to the log file.

    dirFields = fieldnames(projectPaths);
    dirFields(ismember(dirFields, {'logPath', 'logFilePath'})) = [];

    for i = 1:length(dirFields)
        dirPath = projectPaths.(dirFields{i});
        if ~isfolder(dirPath)
            try
                mkdir(dirPath);
                logMessage(['Created directory: ' dirPath], logFilePath, 'INFO');
            catch ME
                logMessage(['Failed to create directory ' dirPath ': ' ME.message], logFilePath, 'ERROR');
                error(['Failed to create directory ' dirPath ': ' ME.message]);
            end
        else
            logMessage(['Directory already exists: ' dirPath], logFilePath, 'INFO');
        end
    end
end
