
%% Code for computing frequency spectra on the non laplacian transformed data from Experiment 3.
% Also includes a bit of plotting for exploration

addpath('/eeglab2023.0')
addpath(genpath('/Matlab Code'))
%% extract all folders first

folder = '/Exp3EEG/';
contents = dir(folder);
dirFlags = [contents.isdir];
subFolders = contents(dirFlags);
subjectFolders = {subFolders(4:end).name}; % Start at 3 to skip . and ..


%Exp3Powspect = struct;
datafolder = '/EEG/';
load(strcat(datafolder,'Exp3Powspect.mat'))
eeglab nogui


%% This section is for the proprocessing of the resting state data
% now loop over each folder
Exp3Powspect = struct;
powind = 1;

for subject = 1:length(subjectFolders)

    subjectno = subjectFolders(subject);
    subjectnoidx = isnumber(subjectno{1});
    subjectno = double(string(subjectno{1}(subjectnoidx)));

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

        EEG = pop_loadset( char(filename), char(thissubject));

        hanned = hanning(size(EEG.data,2))'.*EEG.data;
        pow    = (2*abs(fft(hanned,[],2)/size(EEG.data,2))).^2;
        hz     = linspace(0,EEG.srate/2,floor(size(EEG.data,2)/2)+1);
        pow    = pow(:,1:length(hz),:);
        norm   = diff(hz);
        pow    = mean(pow,3);

        theta  = dsearchn(hz',[4 7]');
        psdth  = sum(pow(:,theta(1):theta(2)).*norm(1),2);

        alpha  = dsearchn(hz',[8 12]');
        psdal  = sum(pow(:,alpha(1):alpha(2)).*norm(1),2);

        beta   = dsearchn(hz',[13 30]');
        psdb   = sum(pow(:,beta(1):beta(2)).*norm(1),2);

        delta  = dsearchn(hz',[1 3]');
        psdd  = sum(pow(:,delta(1):delta(2)).*norm(1),2);

        TBR = psdth./psdb;

        if contains(filename,'RS1')
            recording = "RS1";
        elseif contains(filename,'RS2')
            recording = "RS2";
        end

        Exp3Powspect(powind).Subject = subjectFolders{subject};
        Exp3Powspect(powind).Recording = recording;
        Exp3Powspect(powind).Pow = pow;
        Exp3Powspect(powind).Hz = hz;
        Exp3Powspect(powind).Chan = {EEG.chanlocs(:).labels};
        Exp3Powspect(powind).Theta = psdth;
        Exp3Powspect(powind).Alpha = psdal;
        Exp3Powspect(powind).Beta = psdb;
        Exp3Powspect(powind).Delta = psdd;
        Exp3Powspect(powind).TBR = TBR;
        powind = powind + 1;

        clear EEG

    end

end

save(strcat(datafolder,'Exp3Powspect.mat'),"Exp3Powspect")



