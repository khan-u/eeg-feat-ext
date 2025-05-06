function call_python_bycycle(metaDataExtFilePath, logFilePath)
    % CALL_PYTHON_BYCYCLE Calls the Python script for Theta Burst Extraction.
    %
    % Syntax:
    %   call_python_bycycle(metaDataExtFilePath, logFilePath)
    %
    % Description:
    %   Automates the setup of a Python virtual environment, installs dependencies,
    %   and executes the external Python script 'RunBycycle.py' using MATLAB's system calls.
    %   Captures and logs all Python terminal outputs.
    %
    % Inputs:
    %   metaDataExtFilePath - (string) Path to the metaDataExt.mat file.
    %   logFilePath - (string) Path to the log file.
    %
    % Outputs:
    %   None (the function executes the Python script and handles logging).
    %
    % See Also:
    %   MAIN, logMessage

    %% Load metaDataExt Structure from MAT-File
    try
        load(metaDataExtFilePath);
        logMessage('Loaded metaDataExt from MAT-file.', logFilePath, 'INFO');
    catch ME
        logMessage(sprintf('Failed to load metaDataExt.mat: %s', ME.message), logFilePath, 'ERROR');
        error('Failed to load metaDataExt.mat.');
    end

    %% Detect Python Executable
    pythonExe = detect_python();
    if isempty(pythonExe)
        logMessage('Python executable not found.', logFilePath, 'ERROR');
        error('Python executable not found.');
    end

    %% Define Paths
    requirementsPath = fullfile(metaDataExt.projectPaths.basePath, 'requirements.txt');
    venvDir = fullfile(metaDataExt.projectPaths.codePath, 'venv');
    runBycycleFilePath = fullfile(metaDataExt.projectPaths.codePath, 'RunBycycle.py');
    pythonEngineDir = metaDataExt.projectPaths.pythonEngineDir; % Ensure this is correctly defined in metaDataExt

    %% Step 1a: Create Virtual Environment 
    if ~exist(venvDir, 'dir')
        logMessage('Creating Python virtual environment...', logFilePath, 'INFO');
        cmd_create_venv = sprintf('"%s" -m venv "%s"', pythonExe, venvDir);
        [status, cmdOutput] = system(cmd_create_venv);

        % Display and log the virtual environment creation output
        disp(cmdOutput);
        logMessage(cmdOutput, logFilePath, 'INFO');

        if status ~= 0
            logMessage('Failed to create virtual environment.', logFilePath, 'ERROR');
            error('Failed to create virtual environment.');
        end
        logMessage('Virtual environment created successfully.', logFilePath, 'INFO');
    else
        logMessage('Python virtual environment already exists.', logFilePath, 'INFO');
    end

    %% Set pyenv before any Python calls
    venvPython = get_python_executable(venvDir);
    pyenv('Version', venvPython);

    %% Step 1b: Install MATLAB Engine in the Virtual Environment
    logMessage('Installing MATLAB Engine in the virtual environment...', logFilePath, 'INFO');
    installCommand = ['cd "' pythonEngineDir '" && "' venvPython '" setup.py install'];

    [status, cmdOut] = system(installCommand);

    % Display and log the installation output
    disp(cmdOut);
    logMessage(cmdOut, logFilePath, 'INFO');

    if status ~= 0
        logMessage('Failed to install MATLAB Engine in the virtual environment.', logFilePath, 'ERROR');
        error('Failed to install MATLAB Engine in the virtual environment.');
    end
    logMessage('MATLAB Engine installed successfully in the virtual environment.', logFilePath, 'INFO');

    %% Verify MATLAB Engine Availability
    try
        eng = py.matlab.engine.start_matlab();
        eng.quit(); % Close the MATLAB engine if it's not needed immediately
        logMessage('MATLAB Engine is available in the virtual environment.', logFilePath, 'INFO');
    catch ME
        disp('MATLAB Engine is not available in the current Python environment.');
        disp(ME.message);
        logMessage(sprintf('MATLAB Engine not available: %s', ME.message), logFilePath, 'ERROR');
        error('Cannot proceed without MATLAB Engine.');
    end

    %% Step 2: Install Dependencies from requirements.txt
    pipExe = get_pip_executable(venvDir);
    if isempty(pipExe) || ~isfile(pipExe)
        logMessage('pip executable not found in the virtual environment.', logFilePath, 'ERROR');
        error('pip executable not found in the virtual environment.');
    end

    if isfile(requirementsPath)
        logMessage('Installing Python dependencies...', logFilePath, 'INFO');

        % Upgrade pip using the recommended method with the Python executable
        cmd_upgrade_pip = sprintf('"%s" -m pip install --upgrade pip', venvPython);
        [status, cmdOutput] = system(cmd_upgrade_pip);

        % Display and log the pip upgrade output
        disp(cmdOutput);  % Display in Command Window
        logMessage(cmdOutput, logFilePath, 'INFO');  % Log to file

        if status ~= 0
            logMessage('Failed to upgrade pip.', logFilePath, 'ERROR');
            error('Failed to upgrade pip.');
        end

        % Install dependencies from requirements.txt
        cmd_install_deps = sprintf('"%s" install -r "%s"', pipExe, requirementsPath);
        [status, cmdOutput] = system(cmd_install_deps);

        % Display and log the dependencies installation output
        disp(cmdOutput);  % Display in Command Window
        logMessage(cmdOutput, logFilePath, 'INFO');  % Log to file

        if status ~= 0
            logMessage('Failed to install Python dependencies.', logFilePath, 'ERROR');
            error('Failed to install Python dependencies.');
        end
        logMessage('Python dependencies installed successfully.', logFilePath, 'INFO');
    else
        logMessage('requirements.txt not found. Skipping dependency installation.', logFilePath, 'WARNING');
    end

    %% Step 3: Execute the Python Script within the Virtual Environment
    logMessage('Executing RunBycycle.py...', logFilePath, 'INFO');

    % Verify the metaDataExt.mat file exists
    if ~isfile(metaDataExtFilePath)
        logMessage(sprintf('metaDataExt.mat not found at path: %s', metaDataExtFilePath), ...
            logFilePath, 'ERROR');
        error('metaDataExt.mat not found at path: %s', metaDataExtFilePath);
    end

    % Create a unique temporary log file to capture Python script output
    tempLogFile = [tempname, '.log'];

    % Construct the command to run the Python script and redirect output to the temp log file
    cmd_run_python = sprintf('"%s" "%s" --csv_path="%s" --preProcessedPath="%s" --meta_data_path="%s" > "%s" 2>&1', ...
        venvPython, runBycycleFilePath, metaDataExt.projectPaths.cycleFeaturesPath, metaDataExt.projectPaths.preProcessedPath, metaDataExtFilePath, tempLogFile);

    % Execute the command
    [status, ~] = system(cmd_run_python);

    %% Read and Log Python Script Output
    try
        if isfile(tempLogFile)
            fileID = fopen(tempLogFile, 'r');
            if fileID == -1
                logMessage(sprintf('Cannot open temporary Python log file: %s', tempLogFile), ...
                    logFilePath, 'WARNING');
            else
                pythonLogContents = fread(fileID, '*char')';
                fclose(fileID);
                delete(tempLogFile);  % Remove the temporary log file after reading

                % Display the Python output in the MATLAB Command Window
                disp(pythonLogContents);

                % Append the Python output to the main log file
                logMessage(pythonLogContents, logFilePath, 'INFO');
            end
        else
            logMessage('Temporary Python log file not found.', logFilePath, 'WARNING');
        end
    catch ME
        logMessage(sprintf('Failed to read Python log file: %s', ME.message), ...
            logFilePath, 'ERROR');
    end

    %% Check the Status of the Python Script Execution
    if status ~= 0
        logMessage('Python script execution failed.', logFilePath, 'ERROR');
        error('Python script execution failed.');
    end

    logMessage('Python script executed successfully.', logFilePath, 'INFO');

    %% Gracefully Shutdown MATLAB
    shutdownMessage = ['MATLAB will shut down in 10 seconds. All data has been processed and saved in the ', ...
                      'appropriate directories. A detailed log of the operations has been recorded in the logs directory.'];
    disp(shutdownMessage);
    pause(10);
    quit force;
end

%% Helper Functions

function pythonExe = detect_python()
    % DETECT_PYTHON Detects the Python executable path.
    %
    % Output:
    %   pythonExe - (string) Full path to python.exe or empty if not found.

    try
        % Capture the output of the system command
        [status, cmdOutput] = system('where python');
        if status == 0
            % Split the output into individual paths using newline characters as delimiters
            paths = splitlines(string(cmdOutput));

            % Remove any empty lines that may exist in the output
            paths = paths(~cellfun('isempty', paths));

            % Index the first path
            pythonExe = paths(1);
            return;
        else
            pythonExe = "";
        end
    catch ME
        warning('An error occurred while detecting the Python executable: %s', ME.identifier);
        pythonExe = "";
    end
end

function pipExe = get_pip_executable(venvDir)
    % GET_PIP_EXECUTABLE Returns the path to pip executable within the virtual environment.
    %
    % Input:
    %   venvDir - (string) Path to the virtual environment directory.
    %
    % Output:
    %   pipExe - (string) Full path to pip.exe or pip in venv, empty if not found.

    if ispc
        pipExe = fullfile(venvDir, 'Scripts', 'pip.exe');
    else
        pipExe = fullfile(venvDir, 'bin', 'pip');
    end
end

function pythonExe = get_python_executable(venvDir)
    % GET_PYTHON_EXECUTABLE Returns the path to python executable within the virtual environment.
    %
    % Input:
    %   venvDir - (string) Path to the virtual environment directory.
    %
    % Output:
    %   pythonExe - (string) Full path to python.exe or python in venv, empty if not found.

    if ispc
        pythonExe = fullfile(venvDir, 'Scripts', 'python.exe');
    else
        pythonExe = fullfile(venvDir, 'bin', 'python');
    end
end
