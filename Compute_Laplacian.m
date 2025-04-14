
%% This Code loads the chopped up data and computes the laplace transform on it, for both experiments.
%% It also then computes the Frequency parameters on it and saves the data into the relevant folder.

%%

clear; clc;
rmpath('/eeglab2023.0')
addpath(genpath('/Matlab Code'))
addpath('/fieldtrip-20220426')

%% extract all folders first - Experiment 3
Experiment = 3;
if Experiment == 2
    folder = '/EEGandSCdata/';
    contents = dir(folder);
    dirFlags = [contents.isdir];
    subFolders = contents(dirFlags);
    subjectFolders = {subFolders(3:end).name}; % Start at 3 to skip . and ..
    datafolder = '/SocialSupportHyperalgesiaData/';
elseif Experiment == 3
    folder = '/Exp3EEG/';
    contents = dir(folder);
    dirFlags = [contents.isdir];
    subFolders = contents(dirFlags);
    subjectFolders = {subFolders(4:end).name}; % Start at 3 to skip . and ..
    datafolder = '/EEG/';
end

%% This section is for the proprocessing of the resting state data
% now loop over each folder
Powspect_Lap = struct;
powind = 1;

for subject = 1:length(subjectFolders)

    subjectno = subjectFolders(subject);
    subjectnoidx = isnumber(subjectno{1});
    subjectno = double(string(subjectno{1}(subjectnoidx)));
    disp(subjectno)

    thissubject = strcat(folder,string(subjectFolders(subject)),'/');
    subjectfiles = dir(strcat(thissubject,'*.set'));
    rsfiles = strings(1,1);

    for j = 1:length(subjectfiles)

        if contains(subjectfiles(j).name,'RS1','IgnoreCase',true) & contains(subjectfiles(j).name,'CleanedEpoched','IgnoreCase',true)
            rsfiles(end+1) = string(subjectfiles(j).name);
        end

        if contains(subjectfiles(j).name,'RS2','IgnoreCase',true) & contains(subjectfiles(j).name,'CleanedEpoched','IgnoreCase',true)
            rsfiles(end+1) = string(subjectfiles(j).name);
        end

    end

    if length(rsfiles) == 1
        continue
    end

    for index = 1:2

        filename = rsfiles(index+1);

        cfg = [];
        cfg.dataset = char(strcat(thissubject,filename));
        cfg.demean = 'No';
        cfg.trials = 'All';
        Epoched    = ft_preprocessing(cfg);
        elec = ft_read_sens(char(strcat(thissubject,filename)), 'senstype', 'eeg');
        cfg    = [];
        cfg.method = 'spline';
        cfg.elec         = elec;
        cfg.trials       = 'all';
        cfg.feedback     = 'text';
        data   = ft_scalpcurrentdensity(cfg, Epoched);


        if contains(filename,'RS1')
            recording = "RS1";
        elseif contains(filename,'RS2')
            recording = "RS2";
        end


        if Experiment == 2
            save(strcat(thissubject,'Laplacian_Transformed_SS',num2str(subjectno),'_Epochs_',recording), 'data', '-V7.3')
        elseif Experiment == 3
            save(strcat(thissubject,'Laplacian_Transformed_SS',num2str(subjectno),'_Epochs_',recording), 'data', '-V7.3')
        end

        clear EEG data

    end

end

if Experiment == 2
    save(strcat(datafolder,'Exp2Powspect_Lap.mat'),"Powspect_Lap")
elseif Experiment == 3
    save(strcat(datafolder,'Exp3Powspect_Lap.mat'),"Powspect_Lap")
end




%% Check topography for channel locations


% prepare a layout first
cfg = [];
% cfg.rotate = -90; % still have to figure our how to rotate this
layout = ft_prepare_layout(cfg, Epoched);

cfg = [];
% cfg.layout = 'GSN-HydroCel-129.mat';
cfg.layout = 'easycapM23.mat'
% cfg.layout = layout;
cfg.layout = ft_prepare_layout(cfg);
figure; ft_plot_layout(cfg.layout);


cfg = [];
cfg.xlim = [-1 1];
% cfg.rotate = 90;
% cfg.layout = 'GSN-HydroCel-129.mat';
cfg.layout = 'easycapM23.mat'
% cfg.layout = 'eeg1010.lay';
figure('position',[680 240 1039 420]);
ft_topoplotER(cfg, data); 
colorbar; 


topoplot(mean(mean(EEG.data(:,1:end,:),3),2),EEG.chanlocs,'numcontour',3,'electrodes','on','plotrad',.55);





