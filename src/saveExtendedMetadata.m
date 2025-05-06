function [metaDataExtFilePath, logFilePath] = saveExtendedMetadata(metaDataExt, logFilePath)
    % SAVEEXTENDEDMETADATA Saves the extended metadata to a .mat file.
    %
    % Syntax:
    %   [metaDataExtFilePath, logFilePath] = saveExtendedMetadata(metaDataExt, logFilePath)
    %
    % Description:
    %   Aggregates extended metadata, including project paths, selected regions, and subject inclusion/exclusion
    %   information, and saves it to a designated .mat file. Verifies the integrity of the saved data.
    %   Logs the status of the save operation.
    %
    % Inputs:
    %   metaDataExt - (struct) Extended metadata structure containing additional information.
    %   logFilePath - (string) Path to the log file for recording metadata saving status.
    %
    % Outputs:
    %   metaDataExtFilePath - (string) Path to the saved metaDataExt.mat file.
    %   logFilePath - (string) Path to the log file.
    %
    % Example:
    %   [metaDataExtFilePath, logFilePath] = saveExtendedMetadata(metaDataExt, '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage

    try
        % Define the file path where metaDataExt will be saved
        metaDataExtFilePath = metaDataExt.projectPaths.metaDataExtPath;
        logFilePath = metaDataExt.projectPaths.logFilePath;

        % Save the metaDataExt structure to the specified .mat file
        save(metaDataExtFilePath, 'metaDataExt', '-v7.3');
        
        % Optionally clear metaDataExt from the function workspace
        clearvars metaDataExt
        
        % Load the saved data into a temporary variable for verification
        temp = load(metaDataExtFilePath);
        
        % Define the expected fields
        expectedFields = {'projectPaths', 'finalSelectedRegions', 'includedPatientIDs', 'allPatientIDs', 'trialInfoLabels', 'bycycleTableLabels'};
        
        % Check if all expected fields are present
        if all(isfield(temp.metaDataExt, expectedFields))
            logMessage(sprintf('Extended metadata saved and verified at: %s', metaDataExtFilePath), logFilePath, 'INFO');
        else
            error('Saved extended metadata is missing expected fields.');
        end
    catch ME
        logMessage(sprintf('Error saving extended metadata: %s', ME.message), logFilePath, 'ERROR');
        error('Terminating script due to failed metadata saving.');
    end
end
