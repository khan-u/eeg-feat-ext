function [selectedSubjects, selectedRegions] = selectSubjectsAndRegions(metaData, brainRegions, selectedSubjectIDs, selectedBrainRegions, logFilePath)
    % SELECTSUBJECTSANDREGIONS Selects subjects and brain regions based on user input.
    %
    % Syntax:
    %   [selectedSubjects, selectedRegions] = selectSubjectsAndRegions(metaData, brainRegions, selectedSubjectIDs, selectedBrainRegions, logFilePath)
    %
    % Description:
    %   Filters and validates user-selected subjects and brain regions. Handles cases where
    %   selected items are invalid or undefined.
    %
    % Inputs:
    %   metaData - (struct) Metadata structure containing session IDs.
    %   brainRegions - (struct) Structure containing brain region regex patterns.
    %   selectedSubjectIDs - (string array) User-selected subject IDs or "all" for all subjects.
    %   selectedBrainRegions - (string array) User-selected brain regions or "all" for all regions.
    %   logFilePath - (string) Path to the log file for recording selection status.
    %
    % Outputs:
    %   selectedSubjects - (string array) Validated list of subject IDs for processing.
    %   selectedRegions - (string array) Validated list of brain regions for processing.
    %
    % Example:
    %   [subjects, regions] = selectSubjectsAndRegions(metaData, brainRegions, ["P60cs"], ["HP", "A"], '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage
    
    % Determine Selected Subjects
    if ismember("all", selectedSubjectIDs)
        selectedSubjects = metaData.sessionID;
        logMessage("All subjects selected for processing.", logFilePath, 'INFO');
    else
        validSubjectMask = ismember(selectedSubjectIDs, metaData.sessionID);
        validSubjects = selectedSubjectIDs(validSubjectMask);
        invalidSubjects = selectedSubjectIDs(~validSubjectMask);
        
        selectedSubjects = string(validSubjects);  % Ensure string array
        
        for j = 1:length(invalidSubjects)
            logMessage(sprintf('Subject "%s" is not defined. Skipping.', invalidSubjects(j)), logFilePath, 'WARNING');
        end
    end
    
    % Determine Selected Brain Regions
    if ismember("all", selectedBrainRegions)
        selectedRegions = string(fieldnames(brainRegions));
        logMessage("All brain regions selected for processing.", logFilePath, 'INFO');
    else
        validRegionMask = ismember(selectedBrainRegions, string(fieldnames(brainRegions)));
        validRegions = selectedBrainRegions(validRegionMask);
        invalidRegions = selectedBrainRegions(~validRegionMask);
        
        selectedRegions = string(validRegions);  % Ensure string array
        
        for j = 1:length(invalidRegions)
            logMessage(sprintf('Brain region "%s" is not defined. Skipping.', invalidRegions(j)), logFilePath, 'WARNING');
        end
    end
    
    % Confirmation of Selections
    subjectsStr = strjoin(selectedSubjects, ', ');
    regionsStr = strjoin(selectedRegions, ', ');
    
    logMessage(sprintf('Selected Subject(s): "%s"', subjectsStr), logFilePath, 'INFO');
    logMessage(sprintf('Selected Brain Region(s): "%s"', regionsStr), logFilePath, 'INFO');
    
    % Validate Selections
    if isempty(selectedSubjects)
        logMessage('No valid subjects selected. Terminating script.', logFilePath, 'ERROR');
        error('No valid subjects selected.');
    end
    
    if isempty(selectedRegions)
        logMessage('No valid brain regions selected. Terminating script.', logFilePath, 'ERROR');
        error('No valid brain regions selected.');
    end
end
