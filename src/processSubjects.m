function subjectsData = processSubjects(filteredSelectedSubjects, paths, logFilePath)
    % Loads raw subject data, defines trials, attaches SUA info, and saves pre-processed files.
    %
    % Inputs:
    %   filteredSelectedSubjects - (cell array) Validated subject IDs.
    %   paths                    - (struct) Project paths structure.
    %   logFilePath              - (string) Path to the log file.
    %
    % Outputs:
    %   subjectsData - (struct) Pre-processed data for each subject.

    logMessage('Initializing subjectsData structure.', logFilePath, 'INFO');
    subjectsData = struct();

    logMessage('Verifying presence of "defineTrialsStCat" function.', logFilePath, 'INFO');
    if ~exist('defineTrialsStCat', 'file')
        logMessage('Function "defineTrialsStCat" not found in MATLAB path. Terminating script.', logFilePath, 'ERROR');
        error('Function "defineTrialsStCat" not found.');
    end

    logMessage('Starting subject processing loop.', logFilePath, 'INFO');
    for i = 1:length(filteredSelectedSubjects)
        subjectID = filteredSelectedSubjects{i};
        logMessage(sprintf('Performing preliminary processing of subject: %s.', subjectID), logFilePath, 'INFO');

        try
            subjectDataFilePath = fullfile(paths.rawDataPath, sprintf('%s_allChanSpkRmvl.mat', subjectID));
            logMessage(sprintf('Attempting to load subject data from: %s.', subjectDataFilePath), logFilePath, 'INFO');

            if ~isfile(subjectDataFilePath)
                logMessage(sprintf('Subject data file not found: %s. Skipping subject %s.', subjectDataFilePath, subjectID), logFilePath, 'WARNING');
                continue;
            end
            subjectData = load(subjectDataFilePath);
            logMessage(sprintf('Loaded subject data for %s successfully.', subjectID), logFilePath, 'INFO');

            logMessage('Defining trials using "defineTrialsStCat" function.', logFilePath, 'INFO');
            [subjectData.trial, subjectData.time, subjectData.timestamps, subjectData.trialinfo] = defineTrialsStCat(subjectData, "CAT");
            logMessage('Trial definition completed successfully.', logFilePath, 'INFO');

            if isfield(subjectData, 'datasamples')
                logMessage('Removing "datasamples" field from subject data.', logFilePath, 'INFO');
                subjectData = rmfield(subjectData, 'datasamples');
            end

            suaInfoFilePath = fullfile(paths.rawDataPath, sprintf('%s_suaInfo.mat', subjectID));
            logMessage(sprintf('Checking for SUA info file at: %s.', suaInfoFilePath), logFilePath, 'INFO');

            if isfile(suaInfoFilePath)
                logMessage('Loading SUA info.', logFilePath, 'INFO');
                suaData = load(suaInfoFilePath);
                subjectData.sua = suaData;
                logMessage('SUA info loaded successfully.', logFilePath, 'INFO');
            else
                logMessage(sprintf('SUA info file not found at: %s. Proceeding without SUA data for subject %s.', suaInfoFilePath, subjectID), logFilePath, 'WARNING');
                subjectData.sua = [];
            end

            logMessage(sprintf('Assigning pre-processed data to subjectsData for subject %s.', subjectID), logFilePath, 'INFO');
            subjectsData.(subjectID) = subjectData;

            outputFileName      = sprintf('%s_allChanSpkRmvl_trialInfo.mat', subjectID);
            preProcessedFilePath = fullfile(paths.preProcessedPath, outputFileName);
            logMessage(sprintf('Saving pre-processed data to: %s.', preProcessedFilePath), logFilePath, 'INFO');
            save(preProcessedFilePath, '-struct', 'subjectData', '-v7.3');

            logMessage(sprintf('Completed preliminary processing for subject "%s" at: %s.', subjectID, preProcessedFilePath), logFilePath, 'INFO');

        catch ME
            logMessage(sprintf('Error processing subject %s: %s', subjectID, ME.message), logFilePath, 'ERROR');
        end
    end

    logMessage('Completed preliminary pre-processing of all subjects.', logFilePath, 'INFO');
end
