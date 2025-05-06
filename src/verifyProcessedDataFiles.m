function verifyProcessedDataFiles(selectedSubjectIDs, selectedBrainRegions, projectPaths, logFilePath)
    % VERIFYPROCESSEDDATAFILES Checks the existence of processed data files for selected Subjects.
    %
    % Inputs:
    %   selectedSubjectIDs   - (string array) List of selected Subject session IDs.
    %   selectedBrainRegions - (string array) List of selected brain regions.
    %   projectPaths         - (struct) Structure containing directory paths.
    %   logFilePath          - (string) Path to the log file.
    %
    % Outputs:
    %   None. Logs the verification status of each processed data file.

    % Define required processed data suffixes
    % "_allChanSpkRmvl.mat" and "_<SelectedBrainRegions concatenated>_selectedChanSpkRmvl.mat"
    concatenatedRegions = strjoin(selectedBrainRegions, '_');
    requiredProcessedSuffixes = ["_allChanSpkRmvl.mat", "_" + concatenatedRegions + "_selectedChanSpkRmvl.mat"];

    % Iterate through each selected Subject
    for i = 1:length(selectedSubjectIDs)
        SubjectID = selectedSubjectIDs(i);

        % Iterate through each required suffix
        for j = 1:length(requiredProcessedSuffixes)
            suffix = requiredProcessedSuffixes(j);
            fileName = strcat(SubjectID, suffix);
            filePath = fullfile(projectPaths.preProcessedPath, fileName);

            if isfile(filePath)
                logMessage(['Verified processed data file exists: ' filePath], logFilePath, 'INFO');
            else
                logMessage(['Missing processed data file for Subject "' SubjectID '": ' filePath], logFilePath, 'ERROR');
                error(['Missing processed data file for Subject "' SubjectID '": ' filePath]);
            end
        end
    end

    % Verify consolidated LFP data file
    % Assuming a single consolidated file for all selected Subjects and regions
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
