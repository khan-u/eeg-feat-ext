function [metaDataExtFilePath, logFilePath] = saveExtendedMetadata(metaDataExt, logFilePath)
    % Saves the extended metadata structure to a .mat file and verifies integrity.
    %
    % Inputs:
    %   metaDataExt - (struct) Extended metadata to save.
    %   logFilePath - (string) Path to the log file.
    %
    % Outputs:
    %   metaDataExtFilePath - (string) Path to the saved metaDataExt.mat.
    %   logFilePath         - (string) Path to the log file (passed through).

    try
        metaDataExtFilePath = metaDataExt.projectPaths.metaDataExtPath;
        logFilePath         = metaDataExt.projectPaths.logFilePath;

        save(metaDataExtFilePath, 'metaDataExt', '-v7.3');
        clearvars metaDataExt

        temp = load(metaDataExtFilePath);

        expectedFields = {'projectPaths', 'finalSelectedRegions', 'includedSubjectIDs', ...
                          'allSubjectIDs', 'trialInfoLabels', 'bycycleTableLabels'};

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
