function projectPaths = definePaths()
    % DEFINEPATHS Initializes and returns a structure containing all necessary projectPaths.
    %
    % Outputs:
    %   projectPaths - A structure containing directory paths.

    % Initialize projectPaths structure
    projectPaths = struct();

    % Define the base path as the current working directory
    projectPaths.basePath = pwd;

    % Define subdirectories within the base path
    projectPaths.logPath = fullfile(projectPaths.basePath, 'logs');
    projectPaths.codePath = fullfile(projectPaths.basePath, 'src');
    projectPaths.figuresPath = fullfile(projectPaths.basePath, 'figures');
    projectPaths.dataPath = fullfile(projectPaths.basePath, 'data');
    projectPaths.rawDataPath = fullfile(projectPaths.dataPath, 'raw');
    projectPaths.preProcessedPath = fullfile(projectPaths.dataPath, 'pre-processed');
    projectPaths.recyclePath = fullfile(projectPaths.basePath, 'recycle');
    projectPaths.backupPath = fullfile(projectPaths.basePath, 'backup');
    projectPaths.cycleFeaturesPath = fullfile(projectPaths.dataPath, 'cycle_features');
end
