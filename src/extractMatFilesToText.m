function extractMatFilesToIndividualTextFiles(directoryPath, sizeLimitGB)
    % Function to extract details from each .mat file in the specified directory
    % and write the information into a corresponding .txt file with the same name.
    %
    % Usage: extractMatFilesToIndividualTextFiles('path/to/your/directory', 1)
    % The 'sizeLimitGB' argument specifies the maximum size (in GB) of .mat files to process.

    % Check if the input arguments are provided
    if nargin < 2
        error('Please provide both the directory path and size limit in GB as input arguments.');
    end

    % Validate that the provided path is a directory
    if ~isfolder(directoryPath)
        error('The specified path is not a valid directory.');
    end
    
    % Convert the size limit from GB to bytes
    sizeLimitBytes = sizeLimitGB * 1024^3;
    
    % Get all .mat files in the specified directory and its subdirectories
    matFiles = dir(fullfile(directoryPath, '**', '*.mat'));
    
    % Loop through each .mat file
    for k = 1:length(matFiles)
        matFilePath = fullfile(matFiles(k).folder, matFiles(k).name);
        fileInfo = dir(matFilePath); % Get file information, including size
        
        % Check if the file size exceeds the specified limit
        if fileInfo.bytes > sizeLimitBytes
            fprintf('Skipping %s (%.2f GB) as it exceeds the size limit of %.2f GB.\n', ...
                    matFiles(k).name, fileInfo.bytes / 1024^3, sizeLimitGB);
            continue; % Skip to the next file
        end
        
        % Load the .mat file data
        matData = load(matFilePath);
        
        % Define the output text file path with the same name as the .mat file
        [~, matFileName, ~] = fileparts(matFiles(k).name);
        outputFilePath = fullfile(matFiles(k).folder, [matFileName, '.txt']);
        
        % Open the output text file for writing
        outputFile = fopen(outputFilePath, 'w');
        
        % Check if the file was opened successfully
        if outputFile == -1
            error('Failed to create or open %s.', outputFilePath);
        end
        
        % Write file header information
        fprintf(outputFile, '================================================================================\n');
        fprintf(outputFile, 'File: %s\n', matFiles(k).name);
        fprintf(outputFile, 'Path: %s\n', matFiles(k).folder);
        fprintf(outputFile, 'Size: %.2f MB\n', fileInfo.bytes / 1024^2);
        fprintf(outputFile, '================================================================================\n\n');
        
        % Get the field names of variables in the loaded .mat file
        fieldNames = fieldnames(matData);
        
        % Loop through each variable in the .mat file
        for i = 1:length(fieldNames)
            varName = fieldNames{i};
            varData = matData.(varName);
            
            % Write the variable's name
            fprintf(outputFile, '    ├── %s:\n', varName);
            
            % Process the variable data recursively
            processVar(varData, outputFile, 2);  % Starting at indentation level 2
            
            % Add an extra newline for readability between variables
            fprintf(outputFile, '\n');
        end
        
        % Close the output text file
        fclose(outputFile);
        
        % Clear the loaded data to free memory
        clear matData varName varData;
        
        % Force garbage collection to reclaim memory immediately
        java.lang.System.gc();
    end
    
    % Display a message indicating that the extraction process is complete
    fprintf('Data extraction complete. Text files have been created for each .mat file.\n');
    
    % Nested function to process variables recursively
    function processVar(varData, outputFile, indentLevel)
        indent = repmat('    ', 1, indentLevel);
        if iscell(varData)
            % Handle cell array
            varSize = size(varData);
            varSizeStr = mat2str(varSize);
            fprintf(outputFile, '%s├── Size: %s\n', indent, varSizeStr);
            fprintf(outputFile, '%s├── Data Type: cell\n', indent);
            fprintf(outputFile, '%s├── Element Dimensions:\n', indent);
            
            numElements = numel(varData);
            for j = 1:numElements
                elementData = varData{j};
                fprintf(outputFile, '%s    ├── Element %d:\n', indent, j);
                processVar(elementData, outputFile, indentLevel+2);
            end
        elseif isstruct(varData)
            % Handle struct
            varSize = size(varData);
            varSizeStr = mat2str(varSize);
            fprintf(outputFile, '%s├── Size: %s\n', indent, varSizeStr);
            fprintf(outputFile, '%s├── Data Type: struct\n', indent);
            
            if numel(varData) == 1
                % Single struct
                fieldNamesStruct = fieldnames(varData);
                fprintf(outputFile, '%s├── Fields:\n', indent);
                for f = 1:length(fieldNamesStruct)
                    fieldName = fieldNamesStruct{f};
                    fieldData = varData.(fieldName);
                    fprintf(outputFile, '%s    ├── %s:\n', indent, fieldName);
                    processVar(fieldData, outputFile, indentLevel+2);
                end
            else
                % Array of structs
                fprintf(outputFile, '%s├── Struct array with %d elements\n', indent, numel(varData));
                fieldNamesStruct = fieldnames(varData);
                fprintf(outputFile, '%s├── Fields of first element:\n', indent);
                firstElement = varData(1);
                for f = 1:length(fieldNamesStruct)
                    fieldName = fieldNamesStruct{f};
                    fieldData = firstElement.(fieldName);
                    fprintf(outputFile, '%s    ├── %s:\n', indent, fieldName);
                    processVar(fieldData, outputFile, indentLevel+2);
                end
            end
        else
            % Handle other data types
            varSize = size(varData);
            varSizeStr = mat2str(varSize);
            varClass = class(varData);
            fprintf(outputFile, '%s├── Size: %s\n', indent, varSizeStr);
            fprintf(outputFile, '%s├── Data Type: %s\n', indent, varClass);
        end
    end
end
