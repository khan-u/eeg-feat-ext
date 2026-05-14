function logMessage(message, logFilePath, severity)
    % Logs a timestamped, severity-tagged entry to file and console.
    %
    % Inputs:
    %   message      - (string or char) The message to log.
    %   logFilePath  - (string) Path to the log file.
    %   severity     - (string) 'INFO', 'WARNING', or 'ERROR'.

    validSeverities = {'INFO', 'WARNING', 'ERROR'};
    severity = upper(severity);
    if ~ismember(severity, validSeverities)
        warning('Invalid severity level: "%s". Defaulting to INFO.', severity);
        severity = 'INFO';
    end

    if isstring(message)
        message = char(message);
    elseif ~ischar(message)
        error('The message must be a character vector or a string scalar.');
    end

    safeMessage = strrep(message, '\', '/');
    safeLogFilePath = strrep(logFilePath, '\', '/');

    stack = dbstack(1);
    if ~isempty(stack)
        callerInfo = sprintf('%s (line %d)', stack(1).name, stack(1).line);
    else
        callerInfo = 'Base Workspace';
    end

    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS.FFF');
    logEntry = sprintf('%s [%s] [%s] %s\n', timestamp, severity, callerInfo, safeMessage);

    try
        fid = fopen(safeLogFilePath, 'a');
        if fid == -1
            error('Unable to open log file: %s', safeLogFilePath);
        end
        fprintf(fid, '%s', logEntry);
        fclose(fid);
    catch fileError
        warning('Log file error: %s', getReport(fileError, 'basic'));
    end

    switch severity
        case 'INFO'
            fprintf('INFO: %s\n', safeMessage);
        case 'WARNING'
            fprintf(2, 'WARNING: %s (Caller: %s)\n', safeMessage, callerInfo);
        case 'ERROR'
            fprintf(2, 'ERROR: %s (Caller: %s)\n', safeMessage, callerInfo);
            try
                ex = MException('logMessage:Error', safeMessage);
                ex = addCause(ex, MException(fileError.identifier, fileError.message));
                throw(ex);
            catch nestedError
                warning('Error handling failed: %s', getReport(nestedError, 'basic'));
            end
        otherwise
            fprintf('%s: %s\n', severity, safeMessage);
    end
end
