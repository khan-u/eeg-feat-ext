function [selectedSubjects, selectedRegions] = selectSubjectsAndRegions(metaData, brainRegions, selectedSubjectIDs, selectedBrainRegions, logFilePath)
    % Validates user-selected subjects and brain regions against available options.
    %
    % Inputs:
    %   metaData            - (struct) Metadata with sessionID field.
    %   brainRegions        - (struct) Brain region regex patterns.
    %   selectedSubjectIDs  - (string array) User selection or "all".
    %   selectedBrainRegions- (string array) User selection or "all".
    %   logFilePath         - (string) Path to the log file.
    %
    % Outputs:
    %   selectedSubjects - (string array) Validated subject IDs.
    %   selectedRegions  - (string array) Validated region names.

    if ismember("all", selectedSubjectIDs)
        selectedSubjects = metaData.sessionID;
        logMessage("All subjects selected for processing.", logFilePath, 'INFO');
    else
        validSubjectMask = ismember(selectedSubjectIDs, metaData.sessionID);
        validSubjects    = selectedSubjectIDs(validSubjectMask);
        invalidSubjects  = selectedSubjectIDs(~validSubjectMask);

        selectedSubjects = string(validSubjects);

        for j = 1:length(invalidSubjects)
            logMessage(sprintf('Subject "%s" is not defined. Skipping.', invalidSubjects(j)), logFilePath, 'WARNING');
        end
    end

    if ismember("all", selectedBrainRegions)
        selectedRegions = string(fieldnames(brainRegions));
        logMessage("All brain regions selected for processing.", logFilePath, 'INFO');
    else
        validRegionMask = ismember(selectedBrainRegions, string(fieldnames(brainRegions)));
        validRegions    = selectedBrainRegions(validRegionMask);
        invalidRegions  = selectedBrainRegions(~validRegionMask);

        selectedRegions = string(validRegions);

        for j = 1:length(invalidRegions)
            logMessage(sprintf('Brain region "%s" is not defined. Skipping.', invalidRegions(j)), logFilePath, 'WARNING');
        end
    end

    subjectsStr = strjoin(selectedSubjects, ', ');
    regionsStr  = strjoin(selectedRegions, ', ');

    logMessage(sprintf('Selected Subject(s): "%s"', subjectsStr), logFilePath, 'INFO');
    logMessage(sprintf('Selected Brain Region(s): "%s"', regionsStr), logFilePath, 'INFO');

    if isempty(selectedSubjects)
        logMessage('No valid subjects selected. Terminating script.', logFilePath, 'ERROR');
        error('No valid subjects selected.');
    end

    if isempty(selectedRegions)
        logMessage('No valid brain regions selected. Terminating script.', logFilePath, 'ERROR');
        error('No valid brain regions selected.');
    end
end
