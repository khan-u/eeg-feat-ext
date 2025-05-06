function subjectsData = processSubjects(filteredSelectedSubjects, paths, logFilePath)
    % PROCESSPATIENTS Processes each selected subject and populates subjectsData structure.
    %
    % Syntax:
    %   subjectsData = processSubjects(filteredSelectedSubjects, paths, logFilePath)
    %
    % Description:
    %   Iterates through the list of selected subjects, loads their data, defines trials,
    %   handles SUA information, and saves the processed data to the pre-processed directory.
    %   Logs the status of each subject processing with exhaustive logging.
    %
    % Inputs:
    %   filteredSelectedSubjects - (cell array) List of validated subject IDs for processing.
    %   paths - (struct) A structure containing directory paths as defined by definePaths().
    %   logFilePath - (string) Path to the log file for recording subject processing status.
    %
    % Outputs:
    %   subjectsData - (struct) A structured container holding processed data for each subject.
    %
    % Example:
    %   subjectsData = processSubjects({"P60cs"}, paths, '/path/to/logfile.txt');
    %
    % See Also:
    %   defineTrialsStCat, definePaths, setupLogging, logMessage

    % Start processing and initialize the subjectsData structure
    logMessage('Initializing subjectsData structure.', logFilePath, 'INFO');
    subjectsData = struct();

    % Verify the presence of 'defineTrialsStCat' function
    logMessage('Verifying presence of "defineTrialsStCat" function.', logFilePath, 'INFO');
    if ~exist('defineTrialsStCat', 'file')
        logMessage('Function "defineTrialsStCat" not found in MATLAB path. Terminating script.', logFilePath, 'ERROR');
        error('Function "defineTrialsStCat" not found.');
    end
    
    % Iterate through each selected subject
    logMessage('Starting subject processing loop.', logFilePath, 'INFO');
    for i = 1:length(filteredSelectedSubjects)
        subjectID = filteredSelectedSubjects{i};  % Access subject ID from cell array
        logMessage(sprintf('Performing preliminary processing of subject: %s.', subjectID), logFilePath, 'INFO');
        
        try
            % Load subject data from the 'raw' directory
            subjectDataFilePath = fullfile(paths.rawDataPath, sprintf('%s_allChanSpkRmvl.mat', subjectID));
            logMessage(sprintf('Attempting to load subject data from: %s.', subjectDataFilePath), logFilePath, 'INFO');
            
            if ~isfile(subjectDataFilePath)
                logMessage(sprintf('Subject data file not found: %s. Skipping subject %s.', subjectDataFilePath, subjectID), logFilePath, 'WARNING');
                continue;  % Skip to the next subject
            end
            subjectData = load(subjectDataFilePath);
            logMessage(sprintf('Loaded subject data for %s successfully.', subjectID), logFilePath, 'INFO');
            
            % Define trials using the custom function 'defineTrialsStCat'
            logMessage('Defining trials using "defineTrialsStCat" function.', logFilePath, 'INFO');
            [subjectData.trial, subjectData.time, subjectData.timestamps, subjectData.trialinfo] = defineTrialsStCat(subjectData, "CAT");
            logMessage('Trial definition completed successfully.', logFilePath, 'INFO');
            
            % Check and remove 'datasamples' field if it exists
            if isfield(subjectData, 'datasamples')
                logMessage('Removing "datasamples" field from subject data.', logFilePath, 'INFO');
                subjectData = rmfield(subjectData, 'datasamples');
            end
            
            % Load SUA (Single Unit Activity) information from the 'raw' directory
            suaInfoFilePath = fullfile(paths.rawDataPath, sprintf('%s_suaInfo.mat', subjectID));
            logMessage(sprintf('Checking for SUA info file at: %s.', suaInfoFilePath), logFilePath, 'INFO');
            
            if isfile(suaInfoFilePath)
                logMessage('Loading SUA info.', logFilePath, 'INFO');
                suaData = load(suaInfoFilePath);
                subjectData.sua = suaData;
                logMessage('SUA info loaded successfully.', logFilePath, 'INFO');
            else
                logMessage(sprintf('SUA info file not found: %s. Proceeding without SUA data for subject %s.', suaInfoFilePath, subjectID), logFilePath, 'WARNING');
                subjectData.sua = [];
            end
            
            % Assign the updated subject data to the structured container
            logMessage(sprintf('Assigning pre-processed data to subjectsData structure for subject %s.', subjectID), logFilePath, 'INFO');
            subjectsData.(subjectID) = subjectData;
    
            % Save the updated subject data to the 'pre-processed' directory
            outputFileName = sprintf('%s_allChanSpkRmvl_trialInfo.mat', subjectID);
            preProcessedFilePath = fullfile(paths.preProcessedPath, outputFileName);
            logMessage(sprintf('Saving initial pre-processed data to: %s.', preProcessedFilePath), logFilePath, 'INFO');
            save(preProcessedFilePath, '-struct', 'subjectData', '-v7.3');
            
            % Log successful processing of the subject data
            logMessage(sprintf('Successfully completed preliminary processing and saved data for subject "%s" at: %s.', subjectID, preProcessedFilePath), logFilePath, 'INFO');
        
        catch ME
            % Log any errors encountered during processing
            logMessage(sprintf('Error processing subject %s: %s', subjectID, ME.message), logFilePath, 'ERROR');
        end
    end

    % Log the end of processing
    logMessage('Completed preliminary pre-processing of all subjects.', logFilePath, 'INFO');
end
