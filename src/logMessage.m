function logMessage(message, logFilePath, severity)
    % LOGMESSAGE Logs a message with detailed contextual information.
    %
    % Inputs:
    %   message      - (string or char) The message to log.
    %   logFilePath  - (string) Path to the log file.
    %   severity     - (string) Severity level: 'INFO', 'WARNING', 'ERROR'.
    %
    % Outputs:
    %   None. Writes log entries to the specified log file and displays messages in MATLAB.

    % Define valid severity levels
    validSeverities = {'INFO', 'WARNING', 'ERROR'};
    severity = upper(severity);
    if ~ismember(severity, validSeverities)
        warning('Invalid severity level: "%s". Defaulting to INFO.', severity);
        severity = 'INFO';
    end

    % Ensure the message is a character vector
    if isstring(message)
        message = char(message);
    elseif ~ischar(message)
        error('The message must be a character vector or a string scalar.');
    end

    % Replace backslashes with forward slashes to avoid escape character issues
    safeMessage = strrep(message, '\', '/');
    safeLogFilePath = strrep(logFilePath, '\', '/');

    % Capture calling function and line number for context
    stack = dbstack(1);  % Get caller's stack trace
    if ~isempty(stack)
        callerInfo = sprintf('%s (line %d)', stack(1).name, stack(1).line);
    else
        callerInfo = 'Base Workspace';
    end

    % Get current timestamp with milliseconds precision
    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');

    % Construct the log entry using safeMessage
    logEntry = sprintf('%s [%s] [%s] %s\n', timestamp, severity, callerInfo, safeMessage);

    % Attempt to write to the log file using safeLogFilePath
    try
        fid = fopen(safeLogFilePath, 'a');
        if fid == -1
            error('Unable to open log file: %s', safeLogFilePath);
        end
        fprintf(fid, '%s', logEntry);
        fclose(fid);  % Ensure the file is closed immediately after writing
    catch fileError
        % Log file error in MATLAB command window using appropriate formatting
        warning('Log file error: %s', getReport(fileError, 'basic'));
    end

    % Display the message with severity-specific formatting
    switch severity
        case 'INFO'
            fprintf('INFO: %s\n', safeMessage);
        case 'WARNING'
            fprintf(2, 'WARNING: %s (Caller: %s)\n', safeMessage, callerInfo); % Use stderr
        case 'ERROR'
            fprintf(2, 'ERROR: %s (Caller: %s)\n', safeMessage, callerInfo); % Use stderr
            % Include a stack trace on errors
            try
                % Create an MException to generate a stack trace
                ex = MException('logMessage:Error', safeMessage);
                ex = addCause(ex, MException(fileError.identifier, fileError.message));
                throw(ex);
            catch nestedError
                % Use getReport for more detailed information
                warning('Error handling failed: %s', getReport(nestedError, 'basic'));
            end
        otherwise
            fprintf('%s: %s\n', severity, safeMessage);
    end
end
