function saveFolderTree(rootPath, outputFileName)
    % Function to extract and save folder structure (including files) as a fully nested tree to a text file
    %
    % Inputs:
    %   rootPath - The root directory path as a string
    %   outputFileName - The name of the text file where the tree will be saved
    %
    % Example usage:
    %   saveFolderTree('C:\Users\YourName\Documents\Project', 'folder_tree.txt');

    % Open the output file in write mode
    fileID = fopen(outputFileName, 'w');
    
    % Call the recursive function to print the folder and file structure to file
    printFolderTree(rootPath, '', true, fileID);
    
    % Close the file
    fclose(fileID);
end

function printFolderTree(folderPath, indent, isLast, fileID)
    % Helper function to recursively print the folder and file structure
    %
    % Inputs:
    %   folderPath - Current folder path as a string
    %   indent - Current indentation level as a string
    %   isLast - Boolean indicating if this is the last child node
    %   fileID - File identifier for the text file

    % Get the folder name from the path
    [~, folderName] = fileparts(folderPath);

    % Print the current folder with the appropriate structure symbols
    if isLast
        fprintf(fileID, '%s└── %s\n', indent, folderName);
        newIndent = [indent '    ']; % Add spacing for the next level
    else
        fprintf(fileID, '%s├── %s\n', indent, folderName);
        newIndent = [indent '│   ']; % Add a vertical line for the next level
    end

    % Get the list of all subfolders and files in the current folder
    items = dir(folderPath);
    items = items(~ismember({items.name}, {'.', '..'})); % Remove '.' and '..' entries

    % Separate items into folders and files
    subFolders = items([items.isdir]);
    files = items(~[items.isdir]);

    % Sort folders and files alphabetically for consistency
    [~, sortIdxFolders] = sort(lower({subFolders.name}));
    subFolders = subFolders(sortIdxFolders);

    [~, sortIdxFiles] = sort(lower({files.name}));
    files = files(sortIdxFiles);

    % Recursively print each subfolder
    numSubFolders = length(subFolders);
    for i = 1:numSubFolders
        isLastSubFolder = (i == numSubFolders) && isempty(files);
        printFolderTree(fullfile(folderPath, subFolders(i).name), newIndent, isLastSubFolder, fileID);
    end

    % Print each file in the current folder
    numFiles = length(files);
    for i = 1:numFiles
        isLastFile = (i == numFiles);
        if isLastFile
            fprintf(fileID, '%s└── %s\n', newIndent, files(i).name);
        else
            fprintf(fileID, '%s├── %s\n', newIndent, files(i).name);
        end
    end
end
