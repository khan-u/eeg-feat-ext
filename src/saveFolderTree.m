function saveFolderTree(rootPath, outputFileName)
    % Exports the project folder structure as a nested ASCII tree to a text file.
    %
    % Inputs:
    %   rootPath       - (string) Root directory path.
    %   outputFileName - (string) Output text file path.

    fileID = fopen(outputFileName, 'w');
    printFolderTree(rootPath, '', true, fileID);
    fclose(fileID);
end

function printFolderTree(folderPath, indent, isLast, fileID)
    [~, folderName] = fileparts(folderPath);

    if isLast
        fprintf(fileID, '%s└── %s\n', indent, folderName);
        newIndent = [indent '    '];
    else
        fprintf(fileID, '%s├── %s\n', indent, folderName);
        newIndent = [indent '│   '];
    end

    items = dir(folderPath);
    items = items(~ismember({items.name}, {'.', '..'}));

    subFolders = items([items.isdir]);
    files = items(~[items.isdir]);

    [~, sortIdxFolders] = sort(lower({subFolders.name}));
    subFolders = subFolders(sortIdxFolders);

    [~, sortIdxFiles] = sort(lower({files.name}));
    files = files(sortIdxFiles);

    numSubFolders = length(subFolders);
    for i = 1:numSubFolders
        isLastSubFolder = (i == numSubFolders) && isempty(files);
        printFolderTree(fullfile(folderPath, subFolders(i).name), newIndent, isLastSubFolder, fileID);
    end

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
