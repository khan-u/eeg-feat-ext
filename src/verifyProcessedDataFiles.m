function verifyProcessedDataFiles(selectedSubjectIDs, selectedBrainRegions, projectPaths, logFilePath)
    % Checks that pre-processed output files exist for each selected subject and region.
    %
    % Inputs:
    %   selectedSubjectIDs   - (string array) Selected subject session IDs.
    %   selectedBrainRegions - (string array) Selected brain region names.
    %   projectPaths         - (struct) Structure containing directory paths.
    %   logFilePath          - (string) Path to the log file.

    concatenatedRegions = strjoin(selectedBrainRegions, '_');
    requiredProcessedSuffixes = ["_allChanSpkRmvl.mat", ...
                                 "_" + concatenatedRegions + "_selectedChanSpkRmvl.mat"];

    for i = 1:length(selectedSubjectIDs)
        SubjectID = selectedSubjectIDs(i);

        for j = 1:length(requiredProcessedSuffixes)
            suffix   = requiredProcessedSuffixes(j);
            fileName = strcat(SubjectID, suffix);
            filePath = fullfile(projectPaths.preProcessedPath, fileName);

            if isfile(filePath)
                logMessage(['Verified processed data file exists: ' filePath], logFilePath, 'INFO');
            else
                logMessage(['Missing processed data file for subject "' SubjectID '": ' filePath], logFilePath, 'ERROR');
                error(['Missing processed data file for subject "' SubjectID '": ' filePath]);
            end
        end
    end

    concatenatedSubjectIDs = strjoin(selectedSubjectIDs, '_');
    consolidatedFileName = strcat(concatenatedSubjectIDs, "_" + concatenatedRegions + "_selectedChanSpkRmvlConsolidated.mat");
    consolidatedFilePath = fullfile(projectPaths.preProcessedPath, consolidatedFileName);

    if isfile(consolidatedFilePath)
        logMessage(['Verified consolidated LFP data file exists: ' consolidatedFilePath], logFilePath, 'INFO');
    else
        logMessage(['Missing consolidated LFP data file: ' consolidatedFilePath], logFilePath, 'ERROR');
        error(['Missing consolidated LFP data file: ' consolidatedFilePath]);
    end
end
