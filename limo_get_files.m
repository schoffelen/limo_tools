function [Names,Paths,Files,txtFile] = limo_get_files(varargin)

% routine to get multifiles from different directories
%
% FORMAT [Names,Paths,Files] = limo_get_files(gp,filter,title)
%        [Names,Paths,Files] = limo_get_files([],[],[],'file_list.txt')
%
% INPUT can be left empty, in the case ask for .mat or .txt
%       gp  is a simple numerical value, so the selection question reminds
%           the user which group is getting selected 
%       filter allows to specify the type of files to load,
%              for instance {'*.txt;*.set'} means load mat or txt
%              supported formats are .mat .txt .set .study
%              default is {'*.mat;*.txt'}
%              e.g. [Names,Paths,Files] = limo_get_files([],{'*.set'})
%      title a default question dialogue is 'select a subject file or list
%            file' with possible the gp number inserted, but this can be
%            customized here
%      [hack] files already selected file names to split 
%             [Names,Paths,Files] = limo_get_files([],[],[],'file_list.txt')
%
% OUTPUT Names , Paths, Full File names are returned as cells
%
% Cyril Pernet 25-08-09
% Nicolas Chauveau 07-04-11 - allows txt files
% CP update for filter and additional format 01-21-2015
% Arnaud Delorme fixed delimiters and added study option June 2015
% ------------------------------
%  Copyright (C) LIMO Team 2019

%% defaults and inputs
gp        = [];
guititle  = 'select a file or list file';
filter    = {'*.mat;*.txt'};
path2file = [];
txtFile   = '';

if nargin >= 1
    gp        = varargin{1}; 
end

if nargin >= 2 && ~isempty(varargin{2})
    filter    = varargin{2}; 
end

if ~ispc
    filter(:,2) = {';'};
    filter = filter';
    filter = strcat(filter{:});
end

if nargin >= 3
    guititle = varargin{3};
end
 
if nargin == 4
    path2file = varargin{4};
    if iscell(path2file)
        path2file = cell2mat(path2file);
    end
end

go = 1; index = 1; 
Names = []; Paths = []; Files = [];
while go == 1
    if isempty(path2file)
        if ~isempty(gp) 
            guititle = ['Select a file or list file gp: ' num2str(gp)];
        end
        % propose files to user
        limo_settings_script;
        name = '';
        if ~isempty(limo_settings.workdir)
            fileList1 = dir(fullfile(limo_settings.workdir, 'LIMO_*', 'Beta*'));
            fileList2 = dir(fullfile(limo_settings.workdir, 'LIMO_*', 'con_*'));
            fileList3 = dir(fullfile(limo_settings.workdir, 'LIMO_*', 'Between_sessions_con_*'));
            fileList = [ fileList1;fileList2;fileList3 ];
            if ~isempty(fileList)
                for iFile = 1:length(fileList)
                    fileList(iFile).fullname = fullfile(fileList(iFile).folder,fileList(iFile).name);
                end
                uiList = { {'style' 'text' 'string' 'Pick a 1st level analysis file (beta or contrast)' } ...
                           { 'style' 'popupmenu' 'string' {fileList.name} } };
                res = inputgui('uilist', uiList, 'geometry', { [1] [1] }); % , 'cancel', 'Browse');
                if ~isempty(res)
                    name = fileList(res{1}).name;
                    path = fileList(res{1}).folder;
                end
            end
        end
        
        if isempty(name)
            [name,path] = uigetfile(filter,guititle);
        end
        txtFile = fullfile(path, name);
    else
        if exist(path2file,'file') 
            [path,filename,filext] = fileparts(path2file);
            name = [filename filext]; clear filename filext;
        else
            limo_errordlg(sprintf('A valid path to the file must be provided \n %s not found',path2file));
            return
        end
    end
    
    if name == 0
        go = 0; % exit
    elseif strcmp(name(end-2:end),'mat') || strcmp(name(end-2:end),'set') % select mat files
        Names{index} = name;
        Paths{index} = path;
        Files{index} = fullfile(path,name);
        cd(path); cd ..
        index = index + 1;
    elseif strcmp(name(end-4:end),'study')  % select study file
        load('-mat', name);       
        for f=1:size(STUDY.datasetinfo,2)
            Names{f} = STUDY.datasetinfo(f).filename;
            Paths{f} = STUDY.datasetinfo(f).filepath;
            Files{f} = fullfile(Paths{f},Names{f});
        end
        index = f; go = 0;
    elseif strcmp(name(end-2:end),'txt')
        group_files = textread(fullfile(path,name),'%s','delimiter','');  % select a txt file listing all files
        for f=1:size(group_files,1)
            Files{f}            = group_files{f};
            [Paths{f},NAME,EXT] = fileparts(group_files{f});
            Names{f}            = [NAME EXT];
        end
        index = f; go = 0;
    else
        limo_errordlg('format not supported'); go = 0; 
        return
    end

    if gp == 1 %% since it was set as one group donæt ask again
        go = 0;
    end
end

   

