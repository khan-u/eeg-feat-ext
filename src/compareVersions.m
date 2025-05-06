function result = compareVersions(v1, v2)
    % COMPAREVERSIONS Compares two version strings.
    %
    % Inputs:
    %   v1, v2 - (string) Version strings, e.g., '1.25.0'
    %
    % Outputs:
    %   result - (-1, 0, 1) Returns -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
    
    parts1 = sscanf(v1, '%d.');
    parts2 = sscanf(v2, '%d.');
    maxLength = max(length(parts1), length(parts2));
    parts1(end+1:maxLength) = 0;
    parts2(end+1:maxLength) = 0;
    
    for i = 1:maxLength
        if parts1(i) < parts2(i)
            result = -1;
            return;
        elseif parts1(i) > parts2(i)
            result = 1;
            return;
        end
    end
    result = 0;
end
