function logFilePath = setupLogging(logPath)
    % SETUPLOGGING Initializes the logging system by creating a uniquely named log file.
    %
    % Inputs:
    %   logPath - (string) Directory path where log files are stored.
    %
    % Outputs:
    %   logFilePath - (string) Full path to the created log file.

    % Ensure the log directory exists
    if ~isfolder(logPath)
        mkdir(logPath);
    end

    % Create a uniquely named log file based on current date and time
    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    logFileName = sprintf('MATLAB-console-log_%s.log', timestamp);
    logFilePath = fullfile(logPath, logFileName);

    % Create the log file
    fid = fopen(logFilePath, 'w');
    if fid == -1
        error(['Unable to create log file: ' logFilePath]);
    end
    fclose(fid);

    % Log the creation of the log file
    logMessage(['Log file created: ' logFilePath], logFilePath, 'INFO');
end
