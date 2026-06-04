function projectPaths = setupProject(selectedSubjectIDs)
    % Initializes the project: defines paths, creates directories, verifies files,
    % checks raw data for selected subjects, and validates metaData.mat.
    %
    % Inputs:
    %   selectedSubjectIDs - (string array) Selected subject session IDs.
    %
    % Outputs:
    %   projectPaths - (struct) Fully initialized project paths structure.

    projectPaths = definePaths();

    projectPaths.logFilePath = setupLogging(projectPaths.logPath);
    logMessage('Starting project setup...', projectPaths.logFilePath, 'INFO');

    try
        createDirectories(projectPaths, projectPaths.logFilePath);
        logMessage('Required directories are set up.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['Directory creation failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    try
        verifyAndMoveFiles(projectPaths, projectPaths.logFilePath);
        logMessage('All required files are verified and correctly placed.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['File verification/movement failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    try
        verifyRawDataFiles(selectedSubjectIDs, projectPaths, projectPaths.logFilePath);
        logMessage('All required raw data files are present.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['Raw data verification failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    try
        checkMetaDataFile(projectPaths, projectPaths.logFilePath);
        logMessage('metaData.mat verification completed.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['metaData.mat verification failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    logMessage('Project setup completed successfully.', projectPaths.logFilePath, 'INFO');
end
