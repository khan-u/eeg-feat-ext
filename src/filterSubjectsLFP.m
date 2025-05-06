function [filteredSubjectsData, metaDataExt] = filterSubjectsLFP(subjectsData, finalSelectedRegions, paths, logFilePath)
    % FILTERPATIENTS Filters out subjects missing LFP data from any selected brain regions.
    %
    % Syntax:
    %   [filteredSubjectsData, metaDataExt] = filterSubjects(subjectsData, finalSelectedRegions, paths, logFilePath)
    %
    % Description:
    %   Evaluates each subject's data to ensure they have complete LFP information across all
    %   selected brain regions. Excludes subjects with missing data and logs the exclusion reasons.
    %
    % Inputs:
    %   subjectsData - (struct) A structured container holding processed data for each subject.
    %   finalSelectedRegions - (string array) List of validated brain regions for processing.
    %   paths - (struct) A structure containing directory paths as defined by definePaths().
    %   logFilePath - (string) Path to the log file for recording subject filtering status.
    %
    % Outputs:
    %   filteredSubjectsData - (struct) A structured container holding data for subjects with complete LFP data.
    %   metaDataExt - (struct) Extended metadata containing paths, selections, and subject inclusion/exclusion information.
    %
    % Example:
    %   [filteredData, extendedMeta] = filterSubjects(subjectsData, ["HP", "A"], paths, '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage
    
    % Retrieve the list of subject IDs
    fieldsList = fieldnames(subjectsData);
    tempfinalSelectedRegions = cellstr(finalSelectedRegions); % For regex pattern matching
    
    % Initialize containers for filtered and excluded subjects
    filteredSubjectIndices = [];
    excludedSubjects = struct();
    
    % Iterate through each subject to check for missing regions
    for i = 1:length(fieldsList)
        subjectID = fieldsList{i};
        subject = subjectsData.(subjectID);
        
        % Initialize missingRegions as empty string array
        missingRegions = strings(1,0);
        
        % Check each selected brain region for available channels
        for j = 1:length(tempfinalSelectedRegions)
            region = tempfinalSelectedRegions{j};
            regionChanField = sprintf('%s_chan', region);
            
            if ~isfield(subject, regionChanField) || isempty(subject.(regionChanField))
                missingRegions(end+1) = region; %#ok<AGROW>
            end
        end
        
        % Determine if the subject should be included or excluded
        if isempty(missingRegions)
            filteredSubjectIndices(end+1) = i; %#ok<AGROW>
        else
            reason = sprintf('Missing Brain Regions: %s', strjoin(missingRegions, ', '));
            logMessage(sprintf('Subject "%s" is missing data.\nReason: %s.\nSubject "%s" excluded from further processing and analysis.', ...
                subjectID, reason, subjectID), logFilePath, 'WARNING');
            excludedSubjects.(subjectID).missingRegions = missingRegions;
        end
    end
    
    % Extract the filtered subjects data
    filteredSubjectsData = struct();
    selectedRegionsStr = strjoin(finalSelectedRegions, '_');
    
    if ~isempty(filteredSubjectIndices)
        for idx = filteredSubjectIndices
            currentField = fieldsList{idx};
            filteredSubjectData = subjectsData.(currentField);
            filteredSubjectDataFileName = sprintf('%s_%s_selectedChanSpkRmvl.mat', currentField, selectedRegionsStr);
            filteredSubjectDataFilePath = fullfile(paths.preProcessedPath, filteredSubjectDataFileName);
            % Save the updated subject data with selected channels
            save(filteredSubjectDataFilePath,'filteredSubjectData', '-v7.3');
            logMessage(sprintf('Extracted LFP data from [%s] and saved for subject [%s] to: [%s].', ...
                selectedRegionsStr, currentField, filteredSubjectDataFilePath), logFilePath, 'INFO');
            filteredSubjectsData.(currentField) = filteredSubjectData;
        end
    end
    
    % Log the final list of filtered subjects with complete LFP data
    selectedRegionsStr = strjoin(finalSelectedRegions, '_');
    filteredSubjectsStr = strjoin(fieldsList(filteredSubjectIndices), '_');
    
    if isempty(filteredSubjectIndices)
        logMessage('No subjects have complete LFP data for the selected brain region(s).', logFilePath, 'WARNING');
    elseif length(filteredSubjectIndices) > 1
        newFileName = sprintf('%s_%s_selectedChanSpkRmvlConsolidated.mat', filteredSubjectsStr, selectedRegionsStr);
        newFilePath = fullfile(paths.preProcessedPath, newFileName);
        
        save(newFilePath, '-struct', 'filteredSubjectsData', '-v7.3');
        logMessage(sprintf('Consolidated LFP data from [%s] and saved for subject(s) [%s] to: [%s].', ...
            selectedRegionsStr, filteredSubjectsStr, newFilePath), logFilePath, 'INFO');
    else
        logMessage(sprintf('Single subject with complete LFP data for the selected brain region(s).'), logFilePath, 'INFO');
    end
    
    % Prepare extended metadata
    metaDataExt = struct();
    metaDataExt.projectPaths = paths;
    metaDataExt.finalSelectedRegions = finalSelectedRegions;
    metaDataExt.allSubjectIDs = fieldnames(subjectsData);
    metaDataExt.includedSubjectIDs = fieldnames(filteredSubjectsData);
end
