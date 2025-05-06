function projectPaths = setupProject(selectedSubjectIDs)
    % SETUPPROJECT Initializes the project by setting up directories, verifying and moving files,
    % verifying the project structure, ensuring all Python dependencies are met, 
    % and checking for the metaData.mat file.
    %
    % Syntax:
    %   setupProject(selectedSubjectIDs)
    %
    % Description:
    %   This function automates the initial setup of the project by performing the following steps:
    %     1. Defines project paths.
    %     2. Creates necessary directories.
    %     3. Verifies and moves all required files to their appropriate directories.
    %     4. Verifies the existence of all required raw data files for selected Subjects.
    %     5. Checks that all Python packages specified in 'requirements.txt' are installed with the correct versions.
    %     6. Verifies the presence of 'metaData.mat'
    %
    % Inputs:
    %   selectedSubjectIDs - (string array) List of selected Subject session IDs, e.g., ["P60cs", "P62cs"].
    %
    % Example:
    %   selectedSubjectIDs = ["P60cs", "P62cs", "P64cs"];
    %   setupProject(selectedSubjectIDs);
    %
    % See Also:
    %   definePaths, createDirectories, verifyAndMoveFiles, verifyRawDataFiles, 
    %   verifyPythonDependencies, checkMetaDataFile, logMessage

    % Initialize project paths
    projectPaths = definePaths();

    % Setup logging with a timestamped log file name
    projectPaths.logFilePath = setupLogging(projectPaths.logPath);
    logMessage('Starting project setup...', projectPaths.logFilePath, 'INFO');

    % Create necessary directories
    try
        createDirectories(projectPaths, projectPaths.logFilePath);
        logMessage('Required directories are set up.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['Directory creation failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    % Verify and move all required files to their appropriate directories
    try
        verifyAndMoveFiles(projectPaths, projectPaths.logFilePath);
        logMessage('All required files are verified and correctly placed.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['File verification/movement failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    % Verify the existence of required raw data files for selected Subjects
    try
        verifyRawDataFiles(selectedSubjectIDs, projectPaths, projectPaths.logFilePath);
        logMessage('All required raw data files are present.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['Raw data verification failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    % Check for 'metaData.mat' file 
    try
        checkMetaDataFile(projectPaths, projectPaths.logFilePath);
        logMessage('metaData.mat verification completed.', projectPaths.logFilePath, 'INFO');
    catch ME
        logMessage(['metaData.mat verification failed: ' ME.message], projectPaths.logFilePath, 'ERROR');
        error(['Project setup failed: ' ME.message]);
    end

    logMessage('Project setup completed successfully.', projectPaths.logFilePath, 'INFO');
end
