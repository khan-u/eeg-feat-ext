function projectPaths = definePaths()
    % Initializes and returns a structure containing all project directory paths.
    %
    % Outputs:
    %   projectPaths - Struct with fields for each directory in the project.

    projectPaths = struct();

    projectPaths.basePath          = pwd;
    projectPaths.logPath           = fullfile(projectPaths.basePath, 'logs');
    projectPaths.codePath          = fullfile(projectPaths.basePath, 'src');
    projectPaths.figuresPath       = fullfile(projectPaths.basePath, 'figures');
    projectPaths.dataPath          = fullfile(projectPaths.basePath, 'data');
    projectPaths.rawDataPath       = fullfile(projectPaths.dataPath, 'raw');
    projectPaths.preProcessedPath  = fullfile(projectPaths.dataPath, 'pre-processed');
    projectPaths.recyclePath       = fullfile(projectPaths.basePath, 'recycle');
    projectPaths.backupPath        = fullfile(projectPaths.basePath, 'backup');
    projectPaths.cycleFeaturesPath = fullfile(projectPaths.dataPath, 'cycle_features');
end
