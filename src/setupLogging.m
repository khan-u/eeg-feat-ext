function logFilePath = setupLogging(logPath)
    % Initializes the logging system by creating a uniquely named log file.
    %
    % Inputs:
    %   logPath - (string) Directory path where log files are stored.
    %
    % Outputs:
    %   logFilePath - (string) Full path to the created log file.

    if ~isfolder(logPath)
        mkdir(logPath);
    end

    timestamp = datestr(now, 'yyyymmdd_HHMMSS');
    logFileName = sprintf('MATLAB-console-log_%s.log', timestamp);
    logFilePath = fullfile(logPath, logFileName);

    fid = fopen(logFilePath, 'w');
    if fid == -1
        error(['Unable to create log file: ' logFilePath]);
    end
    fclose(fid);

    logMessage(['Log file created: ' logFilePath], logFilePath, 'INFO');
end
