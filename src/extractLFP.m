function subjectsData = extractLFP(subjectsData, brainRegions, finalSelectedRegions, paths, logFilePath)
    % EXTRACTLFP Extracts LFP data from selected brain regions for each subject.
    %
    % Syntax:
    %   subjectsData = extractLFP(subjectsData, brainRegions, finalSelectedRegions, paths, logFilePath)
    %
    % Description:
    %   For each subject, identifies channels corresponding to the selected brain regions using
    %   regex patterns, extracts LFP data for each trial, and saves the updated subject data.
    %   Logs the status of each extraction operation.
    %
    % Inputs:
    %   subjectsData - (struct) A structured container holding processed data for each subject.
    %   brainRegions - (struct) Structure containing brain region regex patterns.
    %   finalSelectedRegions - (string array) List of validated brain regions for processing.
    %   paths - (struct) A structure containing directory paths as defined by definePaths().
    %   logFilePath - (string) Path to the log file for recording LFP extraction status.
    %
    % Outputs:
    %   subjectsData - (struct) Updated structured container with LFP data extracted.
    %
    % Example:
    %   subjectsData = extractLFP(subjectsData, brainRegions, ["HP", "A"], paths, '/path/to/logfile.txt');
    %
    % See Also:
    %   definePaths, setupLogging, logMessage
    
    % Retrieve the list of subject IDs
    fieldsList = fieldnames(subjectsData);
    tempfinalSelectedRegions = cellstr(finalSelectedRegions); % For regex pattern matching
    
    % Iterate through each subject to extract LFP data
    for i = 1:length(fieldsList)
        subjectID = fieldsList{i};  % Use the field name as subjectID
        
        % Load the updated subject data with trial information
        preProcessedFilePath = fullfile(paths.preProcessedPath, sprintf('%s_allChanSpkRmvl_trialInfo.mat', subjectID));
    
        % Validation check #1: Ensure file saved properly from previous step 
        if ~isfile(preProcessedFilePath)
            logMessage(sprintf('File not found: %s. Prior processing step failed. Skipping LFP extraction for subject %s.', preProcessedFilePath, subjectID), logFilePath, 'WARNING');
            continue;  % Skip to the next subject
        end
    
        subject = load(preProcessedFilePath);
    
        % Validation check #2: If file is present, ensure required fields are also present
        requiredFields = {'trial', 'labels', 'channel'};
        missingRequired = false;
        for f = 1:length(requiredFields)
            if ~isfield(subject, requiredFields{f})
                logMessage(sprintf('Field not found: %s. Prior processing step failed. Skipping LFP extraction for subject %s.', requiredFields{f}, subjectID), logFilePath, 'ERROR');
                missingRequired = true;
                break;  % Exit the loop early
            end
        end
        if missingRequired
            continue;  % Skip to the next subject
        end
        
        % ===============================================================================================
        % Define Brain Regions 
        % ===============================================================================================
                
        for j = 1:length(tempfinalSelectedRegions)
            region = tempfinalSelectedRegions{j};  
            pattern = brainRegions.(region);    % Regex pattern for the region
            
            % Find channels matching the current brain region pattern
            choi = regexp(subject.labels, pattern);
            channelMask = ~cellfun(@isempty, choi);
            
            % Define dynamic field names
            regionChanVar = sprintf('%s_chan', region);
            regionLabelsVar = sprintf('%s_labels', region);
            regionDataVar = sprintf('%s_selectedChanSpkRmvl', region);  
            
            % Extract channel indices and labels for the current region
            region_chan = subject.channel(channelMask, 1);  
            region_labels = subject.labels(channelMask, 1);  
            
            % Assign extracted data to dynamic fields without using eval
            subject.(regionChanVar) = region_chan;
            subject.(regionLabelsVar) = region_labels;
            
            % Initialize LFP_data
            LFP_data = cell(length(subject.trial),1); 
            
            cnt=1;
            % Extract LFP data for each trial
            for k = 1:length(subject.trial)
                trialData = subject.trial{k}; 
                LFP_data{cnt} = trialData(:, channelMask);
                cnt=cnt+1;
            end
            
            % Assign LFP_data to the dynamic field with updated naming
            subject.(regionDataVar) = LFP_data;
            
            % Clear LFP_data to prevent data leakage
            clear LFP_data;
        end
        
        % Remove the 'trial' field as it's no longer needed
        if isfield(subject, 'trial')
            subject = rmfield(subject, 'trial');
        end
        
        % Update the structured data container
        subjectsData.(subjectID) = subject;
    end
end
