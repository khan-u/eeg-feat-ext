function [filteredSubjectsData, metaDataExt] = filterSubjectsLFP(subjectsData, finalSelectedRegions, paths, logFilePath)
    % Filters out subjects that are missing LFP data for any of the selected brain regions.
    %
    % Inputs:
    %   subjectsData          - (struct) LFP-extracted data per subject.
    %   finalSelectedRegions  - (string array) Regions that must be present.
    %   paths                 - (struct) Project paths structure.
    %   logFilePath           - (string) Path to the log file.
    %
    % Outputs:
    %   filteredSubjectsData - (struct) Subjects with complete region coverage.
    %   metaDataExt          - (struct) Extended metadata with inclusion/exclusion records.

    fieldsList = fieldnames(subjectsData);
    tempfinalSelectedRegions = cellstr(finalSelectedRegions);

    filteredSubjectIndices = [];
    excludedSubjects = struct();

    for i = 1:length(fieldsList)
        subjectID = fieldsList{i};
        subject   = subjectsData.(subjectID);

        missingRegions = strings(1, 0);

        for j = 1:length(tempfinalSelectedRegions)
            region         = tempfinalSelectedRegions{j};
            regionChanField = sprintf('%s_chan', region);

            if ~isfield(subject, regionChanField) || isempty(subject.(regionChanField))
                missingRegions(end+1) = region; %#ok<AGROW>
            end
        end

        if isempty(missingRegions)
            filteredSubjectIndices(end+1) = i; %#ok<AGROW>
        else
            reason = sprintf('Missing Brain Regions: %s', strjoin(missingRegions, ', '));
            logMessage(sprintf('Subject "%s" is missing data.\nReason: %s.\nSubject "%s" excluded from further processing.', ...
                subjectID, reason, subjectID), logFilePath, 'WARNING');
            excludedSubjects.(subjectID).missingRegions = missingRegions;
        end
    end

    filteredSubjectsData = struct();
    selectedRegionsStr   = strjoin(finalSelectedRegions, '_');

    if ~isempty(filteredSubjectIndices)
        for idx = filteredSubjectIndices
            currentField = fieldsList{idx};
            filteredSubjectData = subjectsData.(currentField);
            filteredSubjectDataFileName = sprintf('%s_%s_selectedChanSpkRmvl.mat', currentField, selectedRegionsStr);
            filteredSubjectDataFilePath = fullfile(paths.preProcessedPath, filteredSubjectDataFileName);
            save(filteredSubjectDataFilePath, 'filteredSubjectData', '-v7.3');
            logMessage(sprintf('Extracted LFP from [%s] and saved for subject [%s] to: [%s].', ...
                selectedRegionsStr, currentField, filteredSubjectDataFilePath), logFilePath, 'INFO');
            filteredSubjectsData.(currentField) = filteredSubjectData;
        end
    end

    filteredSubjectsStr = strjoin(fieldsList(filteredSubjectIndices), '_');

    if isempty(filteredSubjectIndices)
        logMessage('No subjects have complete LFP data for the selected brain region(s).', logFilePath, 'WARNING');
    elseif length(filteredSubjectIndices) > 1
        newFileName = sprintf('%s_%s_selectedChanSpkRmvlConsolidated.mat', filteredSubjectsStr, selectedRegionsStr);
        newFilePath = fullfile(paths.preProcessedPath, newFileName);
        save(newFilePath, '-struct', 'filteredSubjectsData', '-v7.3');
        logMessage(sprintf('Consolidated LFP from [%s] and saved for subject(s) [%s] to: [%s].', ...
            selectedRegionsStr, filteredSubjectsStr, newFilePath), logFilePath, 'INFO');
    else
        logMessage('Single subject with complete LFP data for the selected brain region(s).', logFilePath, 'INFO');
    end

    metaDataExt = struct();
    metaDataExt.projectPaths         = paths;
    metaDataExt.finalSelectedRegions = finalSelectedRegions;
    metaDataExt.allSubjectIDs        = fieldnames(subjectsData);
    metaDataExt.includedSubjectIDs   = fieldnames(filteredSubjectsData);
end
