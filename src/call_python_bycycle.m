function call_python_bycycle(metaDataExtFilePath, logFilePath)
    % Calls the Python bycycle pipeline: sets up a venv, installs dependencies,
    % and executes RunBycycle.py with the required arguments.
    %
    % Inputs:
    %   metaDataExtFilePath - (string) Path to the metaDataExt.mat file.
    %   logFilePath         - (string) Path to the log file.

    try
        load(metaDataExtFilePath);
        logMessage('Loaded metaDataExt from MAT-file.', logFilePath, 'INFO');
    catch ME
        logMessage(sprintf('Failed to load metaDataExt.mat: %s', ME.message), logFilePath, 'ERROR');
        error('Failed to load metaDataExt.mat.');
    end

    pythonExe = detect_python();
    if isempty(pythonExe)
        logMessage('Python executable not found.', logFilePath, 'ERROR');
        error('Python executable not found.');
    end

    requirementsPath    = fullfile(metaDataExt.projectPaths.basePath, 'requirements.txt');
    venvDir             = fullfile(metaDataExt.projectPaths.codePath, 'venv');
    runBycycleFilePath  = fullfile(metaDataExt.projectPaths.codePath, 'RunBycycle.py');
    pythonEngineDir     = metaDataExt.projectPaths.pythonEngineDir;

    if ~exist(venvDir, 'dir')
        logMessage('Creating Python virtual environment...', logFilePath, 'INFO');
        cmd_create_venv = sprintf('"%s" -m venv "%s"', pythonExe, venvDir);
        [status, cmdOutput] = system(cmd_create_venv);
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

    venvPython = get_python_executable(venvDir);
    pyenv('Version', venvPython);

    logMessage('Installing MATLAB Engine in the virtual environment...', logFilePath, 'INFO');
    installCommand = ['cd "' pythonEngineDir '" && "' venvPython '" setup.py install'];
    [status, cmdOut] = system(installCommand);
    disp(cmdOut);
    logMessage(cmdOut, logFilePath, 'INFO');
    if status ~= 0
        logMessage('Failed to install MATLAB Engine in the virtual environment.', logFilePath, 'ERROR');
        error('Failed to install MATLAB Engine in the virtual environment.');
    end
    logMessage('MATLAB Engine installed successfully.', logFilePath, 'INFO');

    try
        eng = py.matlab.engine.start_matlab();
        eng.quit();
        logMessage('MATLAB Engine is available in the virtual environment.', logFilePath, 'INFO');
    catch ME
        disp('MATLAB Engine is not available in the current Python environment.');
        disp(ME.message);
        logMessage(sprintf('MATLAB Engine not available: %s', ME.message), logFilePath, 'ERROR');
        error('Cannot proceed without MATLAB Engine.');
    end

    pipExe = get_pip_executable(venvDir);
    if isempty(pipExe) || ~isfile(pipExe)
        logMessage('pip executable not found in the virtual environment.', logFilePath, 'ERROR');
        error('pip executable not found in the virtual environment.');
    end

    if isfile(requirementsPath)
        logMessage('Installing Python dependencies...', logFilePath, 'INFO');

        cmd_upgrade_pip = sprintf('"%s" -m pip install --upgrade pip', venvPython);
        [status, cmdOutput] = system(cmd_upgrade_pip);
        disp(cmdOutput);
        logMessage(cmdOutput, logFilePath, 'INFO');
        if status ~= 0
            logMessage('Failed to upgrade pip.', logFilePath, 'ERROR');
            error('Failed to upgrade pip.');
        end

        cmd_install_deps = sprintf('"%s" install -r "%s"', pipExe, requirementsPath);
        [status, cmdOutput] = system(cmd_install_deps);
        disp(cmdOutput);
        logMessage(cmdOutput, logFilePath, 'INFO');
        if status ~= 0
            logMessage('Failed to install Python dependencies.', logFilePath, 'ERROR');
            error('Failed to install Python dependencies.');
        end
        logMessage('Python dependencies installed successfully.', logFilePath, 'INFO');
    else
        logMessage('requirements.txt not found. Skipping dependency installation.', logFilePath, 'WARNING');
    end

    logMessage('Executing RunBycycle.py...', logFilePath, 'INFO');

    if ~isfile(metaDataExtFilePath)
        logMessage(sprintf('metaDataExt.mat not found at path: %s', metaDataExtFilePath), logFilePath, 'ERROR');
        error('metaDataExt.mat not found at path: %s', metaDataExtFilePath);
    end

    tempLogFile = [tempname, '.log'];

    cmd_run_python = sprintf('"%s" "%s" --csv_path="%s" --preProcessedPath="%s" --meta_data_path="%s" > "%s" 2>&1', ...
        venvPython, runBycycleFilePath, metaDataExt.projectPaths.cycleFeaturesPath, ...
        metaDataExt.projectPaths.preProcessedPath, metaDataExtFilePath, tempLogFile);

    [status, ~] = system(cmd_run_python);

    try
        if isfile(tempLogFile)
            fileID = fopen(tempLogFile, 'r');
            if fileID == -1
                logMessage(sprintf('Cannot open temporary Python log file: %s', tempLogFile), logFilePath, 'WARNING');
            else
                pythonLogContents = fread(fileID, '*char')';
                fclose(fileID);
                delete(tempLogFile);
                disp(pythonLogContents);
                logMessage(pythonLogContents, logFilePath, 'INFO');
            end
        else
            logMessage('Temporary Python log file not found.', logFilePath, 'WARNING');
        end
    catch ME
        logMessage(sprintf('Failed to read Python log file: %s', ME.message), logFilePath, 'ERROR');
    end

    if status ~= 0
        logMessage('Python script execution failed.', logFilePath, 'ERROR');
        error('Python script execution failed.');
    end

    logMessage('Python script executed successfully.', logFilePath, 'INFO');

    shutdownMessage = ['MATLAB will shut down in 10 seconds. All data has been processed and saved. ' ...
                       'A detailed log has been recorded in the logs directory.'];
    disp(shutdownMessage);
    pause(10);
    quit force;
end

function pythonExe = detect_python()
    try
        [status, cmdOutput] = system('where python');
        if status == 0
            paths = splitlines(string(cmdOutput));
            paths = paths(~cellfun('isempty', paths));
            pythonExe = paths(1);
            return;
        else
            pythonExe = "";
        end
    catch
        pythonExe = "";
    end
end

function pipExe = get_pip_executable(venvDir)
    if ispc
        pipExe = fullfile(venvDir, 'Scripts', 'pip.exe');
    else
        pipExe = fullfile(venvDir, 'bin', 'pip');
    end
end

function pythonExe = get_python_executable(venvDir)
    if ispc
        pythonExe = fullfile(venvDir, 'Scripts', 'python.exe');
    else
        pythonExe = fullfile(venvDir, 'bin', 'python');
    end
end
