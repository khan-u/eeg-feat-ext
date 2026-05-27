function subjectsData = extractLFP(subjectsData, brainRegions, finalSelectedRegions, paths, logFilePath)
    % Extracts LFP data for each selected brain region across all subjects.
    %
    % For each subject, uses regex patterns to find matching channels, pulls
    % trial-by-trial LFP matrices, and stores them in region-keyed fields.
    %
    % Inputs:
    %   subjectsData          - (struct) Pre-processed data per subject.
    %   brainRegions          - (struct) Region name → regex pattern mapping.
    %   finalSelectedRegions  - (string array) Regions to extract.
    %   paths                 - (struct) Project paths structure.
    %   logFilePath           - (string) Path to the log file.
    %
    % Outputs:
    %   subjectsData - Updated struct with region-specific LFP fields added.

    fieldsList = fieldnames(subjectsData);
    tempfinalSelectedRegions = cellstr(finalSelectedRegions);

    for i = 1:length(fieldsList)
        subjectID = fieldsList{i};

        preProcessedFilePath = fullfile(paths.preProcessedPath, sprintf('%s_allChanSpkRmvl_trialInfo.mat', subjectID));

        if ~isfile(preProcessedFilePath)
            logMessage(sprintf('File not found: %s. Skipping LFP extraction for subject %s.', preProcessedFilePath, subjectID), logFilePath, 'WARNING');
            continue;
        end

        subject = load(preProcessedFilePath);

        requiredFields = {'trial', 'labels', 'channel'};
        missingRequired = false;
        for f = 1:length(requiredFields)
            if ~isfield(subject, requiredFields{f})
                logMessage(sprintf('Field "%s" not found. Skipping LFP extraction for subject %s.', requiredFields{f}, subjectID), logFilePath, 'ERROR');
                missingRequired = true;
                break;
            end
        end
        if missingRequired
            continue;
        end

        for j = 1:length(tempfinalSelectedRegions)
            region  = tempfinalSelectedRegions{j};
            pattern = brainRegions.(region);

            choi        = regexp(subject.labels, pattern);
            channelMask = ~cellfun(@isempty, choi);

            regionChanVar   = sprintf('%s_chan', region);
            regionLabelsVar = sprintf('%s_labels', region);
            regionDataVar   = sprintf('%s_selectedChanSpkRmvl', region);

            subject.(regionChanVar)   = subject.channel(channelMask, 1);
            subject.(regionLabelsVar) = subject.labels(channelMask, 1);

            LFP_data = cell(length(subject.trial), 1);
            for k = 1:length(subject.trial)
                LFP_data{k} = subject.trial{k}(:, channelMask);
            end

            subject.(regionDataVar) = LFP_data;
            clear LFP_data;
        end

        if isfield(subject, 'trial')
            subject = rmfield(subject, 'trial');
        end

        subjectsData.(subjectID) = subject;
    end
end
