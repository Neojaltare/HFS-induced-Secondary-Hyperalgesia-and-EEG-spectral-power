%% EEG Spectral Power Analysis Script
% This script processes resting-state EEG data (Experiments 2 and 3) to compare spectral power
% between two sessions (RS1 vs. RS2), using both Laplacian-transformed and non-transformed data.
% 
% Key steps include:
% 1. Loading and selecting participants based on group criteria.
% 2. Averaging power spectra across subjects and plotting topographies.
% 3. Computing power differences (RS2 - RS1) per frequency band and visualizing results.
% 4. Performing statistical tests (t-tests, cluster-based permutation tests using FieldTrip).
% 5. Visualizing significant frequency × electrode clusters.
% 6. Correlating EEG power differences with behavioral measures (e.g., stress, fear, pain ratings).
%
% Final outputs include figures of topographies, channel-wise spectra, and cluster statistics.

%% Laplacian and Non Laplacian Data

%% Load all the relevant data
clear;clc;
Experiment = 3;

if Experiment == 3
    datafolder = '/EEG/';
    data = load(strcat(datafolder,'Exp3Powspect.mat'));
    data = data.Exp3Powspect;
    data_lap = load(strcat(datafolder,'Exp3Powspect_Lap.mat'));
    data_lap = data_lap.Powspect_Lap;

    data_mike = load(strcat(datafolder,'Exp3Powspect_Mike_Lap.mat'));
    data_mike = data_mike.Powspect_Mike_Lap;

    Conditions = readtable('/Exp3HFSdata.xlsx');
    Control = Conditions.participant(Conditions.group == "C");

    tokeep = [];
    idx = 1;
    for part = 1:length(data)
        subject = data(part).Subject;
        subjectnoidx = isnumber(subject);
        subjectno = double(string(subject(subjectnoidx)));
        if ismember(subjectno,Control)
            tokeep(idx) = part;
            idx = idx + 1;
        end
    end

    data = data(tokeep);
    data_lap = data_lap(tokeep);
    data_mike = data_mike(tokeep);
    chanlocs = load('/ANTChanlocs.mat');
    Chanlocs = chanlocs.ANTChanlocs;

elseif Experiment == 2
    datafolder = '/SocialSupportHyperalgesiaData/';
    data = load(strcat(datafolder,'Exp2RSPowspect.mat'));
    data = data.Exp2RSPowspect;
    data_lap = load(strcat(datafolder,'Exp2Powspect_Lap.mat'));
    data_lap = data_lap.Powspect_Lap;

    data_mike = load(strcat(datafolder,'Exp2Powspect_Mike_Lap.mat'));
    data_mike = data_mike.Powspect_Mike_Lap;

    Rawdata = readtable('/RawData.xlsx');
    Rawdata.ParticipantID(string(Rawdata.ParticipantID) == "SS44a") = {'SS44'};
    Rawdata = Rawdata(1:10:height(Rawdata),:);
    Alone = Rawdata.ParticipantID(Rawdata.Condition == "Alone");

    tokeep = [];
    idx = 1;
    for part = 1:length(data)
        participant = string(data(part).Subject);
        for k = 1:length(Alone)
            if string(Alone(k)) == participant
                tokeep(idx) = part;
                idx = idx + 1;
            end
        end
    end

    data = data(tokeep);
    data_lap = data_lap(tokeep);
    data_mike = data_mike(tokeep);
    data = data([1:16,19:end]);
    data_lap = data_lap([1:16,19:end]);
    data_mike = data_mike([1:16,19:end]);
    Chanlocs = data(1).Chanlocs;

    for field = 1:length(data)
        data(field).Alpha = data(field).PSDAL;
        data(field).Beta = data(field).PSDB;
        data(field).Theta = data(field).PSDTH;
        data(field).Delta = data(field).PSDD;
    end

end

addpath('/eeglab2023.0')
addpath(genpath('/Matlab Code'))
eeglab nogui


%% Plotting
%% Plot topography and differences for one of the measures for RS1 and RS2
RS1 = zeros(size(data(1).Chan))';
RS2 = zeros(size(data(1).Chan))';
for ind = 1:2:length(data)
    RS1 = RS1 + data(ind).Beta;
    RS2 = RS1 + data(ind+1).Beta;
end
RS1 = RS1/(length(data)/2);
RS2 = RS2/(length(data)/2);

figure(1)
subplot(231)
topoplot(RS1, Chanlocs, 'electrodes','on');
title('RS1')
% colorbar
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])
subplot(232)
topoplot(RS2, Chanlocs, 'electrodes','on');
title('RS2')
% colorbar
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])
subplot(233)
topoplot(RS2-RS1, Chanlocs, 'electrodes','on');
title('Difference')
% colorbar
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])


RS1 = zeros(size(data_lap(1).Chan));
RS2 = zeros(size(data_lap(1).Chan));
for ind = 1:2:length(data_lap)
    RS1 = RS1 + data_lap(ind).Beta;
    RS2 = RS1 + data_lap(ind+1).Beta;
end
RS1 = RS1/(length(data_lap)/2);
RS2 = RS2/(length(data_lap)/2);


subplot(234)
topoplot(RS1, Chanlocs, 'electrodes','on');
title('RS1 Laplacian')
% colorbar
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])
subplot(235)
topoplot(RS2, Chanlocs, 'electrodes','on');
title('RS2 Laplacian')
% colorbar
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])
subplot(236)
topoplot(RS2-RS1, Chanlocs, 'electrodes','on');
title('Difference')
% caxis([min(RS1)+min(RS1)*.3 max(RS1)-max(RS1)*.3])
% colorbar


%% Plot difference topography and the individual channel power

toplot = 'Alpha';

RS1 = zeros(length(data(1).Chan),length(data)/2);
RS2 = zeros(length(data(1).Chan),length(data)/2);
count = 1;
for i = 1:2:length(data)
    eval([ 'RS1(:,count) = data(i).',toplot,';'])
    eval([ 'RS2(:,count) = data(i+1).',toplot,';'])
    count = count+1;
end

avg1 = nanmean(RS1,2);
avg2 = nanmean(RS2,2);

diff = avg2 - avg1;

figure(1)
subplot(211)
topoplot(diff, Chanlocs, 'electrodes','on');
title('RS2 - RS1')
% colorbar
% caxis([0 3])

subplot(212)
plot(avg1)
hold on
plot(avg2)
legend('RS1','RS2')
xlabel('Channels')
ylabel(['Avg ',toplot])


RS1 = zeros(length(data(1).Chan),length(data)/2);
RS2 = zeros(length(data(1).Chan),length(data)/2);
count = 1;
for i = 1:2:length(data)
    eval([ 'RS1(:,count) = data_lap(i).',toplot,';'])
    eval([ 'RS2(:,count) = data_lap(i+1).',toplot,';'])
    count = count+1;
end

avg1 = nanmean(RS1,2);
avg2 = nanmean(RS2,2);
diff = avg2 - avg1;

% [B,I] = maxk(diff,10)
[Bfield,Ifield] = maxk(diff,10);
temp = logical(zeros(size(diff)));
temp(Ifield) = 1;

figure(2)
subplot(211)
topoplot(diff, Chanlocs, 'electrodes','on');
title('RS2 - RS1')
% colorbar
% caxis([0 3])

subplot(212)
plot(avg1)
hold on
plot(avg2)
legend('RS1','RS2')
xlabel('Channels')
ylabel(['Avg ',toplot])

%% Compare the average power spectra of a single channel for the raw and Laplacian transformed data

toplot = 'Pow';
chan2plot = 129;

RS1 = zeros(length(data(1).Chan), length(data(1).Hz), length(data)/2);
RS2 = zeros(length(data(1).Chan), length(data(1).Hz), length(data)/2);

count = 1;
for i = 1:2:length(data)
    eval([ 'RS1(:,:,count) = data(i).',toplot,';'])
    eval([ 'RS2(:,:,count) = data(i+1).',toplot,';'])
    count = count+1;
end

avgpow1 = nanmean(RS1,3)';
avgpow2 = nanmean(RS2,3)';


figure(1)
subplot(121)
plot(data(1).Hz ,avgpow1(:,chan2plot))
hold on
plot(data(1).Hz ,avgpow2(:,chan2plot))
legend('RS1','RS2')
xlim([0 30])
title(['Raw Data: Channel ',string(chan2plot)])


RS1 = zeros(length(data(1).Chan), length(data(1).Hz), length(data)/2);
RS2 = zeros(length(data(1).Chan), length(data(1).Hz), length(data)/2);


count = 1;
for i = 1:2:length(data)
    eval([ 'RS1(:,:,count) = data_lap(i).',toplot,';'])
    eval([ 'RS2(:,:,count) = data_lap(i+1).',toplot,';'])
    count = count+1;
end

avgpow1 = mean(RS1,3)';
avgpow2 = nanmean(RS2,3)';

subplot(122)
plot(data(1).Hz ,avgpow1(:,chan2plot))
hold on
plot(data(1).Hz ,avgpow2(:,chan2plot))
legend('RS1','RS2')
xlim([0 30])
title(['Transformed: Channel ',string(chan2plot)])



%% Analysis for one dataset at a time

Dat2analyse = data_lap;

numelec = size(Chanlocs,2);
numfreq = length(Dat2analyse(1).Hz);

ps = ones(numelec,numfreq);
ts = zeros(numelec,numfreq);

RS1 = zeros(numelec,numfreq,length(Dat2analyse)/2);
RS2 = zeros(numelec,numfreq,length(Dat2analyse)/2);

count = 1;
for participant = 1:2:length(Dat2analyse)
    RS1(:,:,count) = Dat2analyse(participant).Pow;
    RS2(:,:,count) = Dat2analyse(participant+1).Pow;
    count = count+1;
end

RS1 = double(RS1);
RS2 = double(RS2);

assert(all(~isnan(RS2(:))), 'RS2 contains NaNs');
assert(all(~isnan(RS1(:))), 'RS1 contains NaNs');

for elec = 1:numelec
    for freq = 1:numfreq

        %         [~,ps(elec,freq),~,stats] = ttest(squeeze(RS1(elec,freq,:)),squeeze(RS2(elec,freq,:)),"Tail","left");
        [~,ps(elec,freq),~,stats] = ttest(squeeze(RS1(elec,freq,:)),squeeze(RS2(elec,freq,:)));
        ts(elec,freq) = stats.tstat;

    end
end

[p_fdr, p_masked] = fdr( ps, .1);

hz = Dat2analyse(1).Hz;


delta  = [1 3];
theta  = [4 7];
alpha  = [8 12];
beta   = [13 30];

allfreqs = [delta; theta; alpha; beta];
titles = ["Delta Frequencies","Theta Frequencies","Alpha Frequencies","Beta Frequencies"];

for i = 1:size(allfreqs,1)
    freqrange = allfreqs(i,:);
    freqidx = dsearchn(hz',freqrange');
    freqidx = freqidx(1):freqidx(end);
    numPlots = length(freqidx);
    numCols = ceil(sqrt(numPlots));
    numRows = ceil(numPlots / numCols);

    figure
    for plt = 1:numPlots

        mask = zeros(length(Chanlocs),1);
        mask = ps(:,freqidx(plt))<.1;

        subplot(numRows,numCols,plt)
        %     topoplot(-ts(:,freqidx(plt)), Chanlocs, 'electrodes','on','pmask',mask);
        topoplot(-ts(:,freqidx(plt)), Chanlocs, 'electrodes','on');
        title(['Freq: ',string(hz(freqidx(plt))),' Hz'])
        colorbar
    end
    sgtitle(titles(i))
end



%% Now using fieldtrip

%% Load the data that you have saved.

clear; clc
addpath(genpath('Matlab Code'))
addpath('/fieldtrip-20220426')
addpath('/eeglab2023.0')
ft_defaults
Experiment = 2;
dataset = "Fieldtrip";
if Experiment == 2
    chanlocs = load('EGIChanlocs.mat');
    Chanlocs = chanlocs.EGIChanlocs;
    folder = '/EEGandSCdata/';
    contents = dir(folder);
    dirFlags = [contents.isdir];
    subFolders = contents(dirFlags);
    subjectFolders = {subFolders(3:end).name}; % Start at 3 to skip . and ..
    datafolder = '/SocialSupportHyperalgesiaData/';

    Rawdata = readtable('/RawData.xlsx');
    Rawdata.ParticipantID(string(Rawdata.ParticipantID) == "SS44a") = {'SS44'};
    Rawdata = Rawdata(1:10:height(Rawdata),:);
    Alone = Rawdata.ParticipantID(Rawdata.Condition == "Alone");

    count = 1;
    for i = 1:length(subjectFolders)

        subjectno = subjectFolders(i);
        subjectnoidx = isnumber(subjectno{1});
        subjectno = double(string(subjectno{1}(subjectnoidx)));

        if ~ismember(strcat('SS',string(subjectno)),string(Alone))
            continue
        end

        if subjectno == 25
            continue
        end

        disp(subjectno)


        if dataset == "Original"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*CleanedEpoched*.set'));
        elseif dataset == "Fieldtrip"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*Laplacian_Transformed*.mat'));
        elseif dataset == "Mike"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*Laplacian_Transformed_Mike*.set'));
        end

        for rs = 1:length(subjectfiles)
            if contains(subjectfiles(rs).name,'RS1')
                if dataset == "Original" | dataset == "Mike"
                    cfg = [];
                    cfg.dataset = char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name));
                    cfg.demean = 'No';
                    cfg.trials = 'All';
                    temp1    = ft_preprocessing(cfg);
                elseif dataset == "Fieldtrip"
                    temp1 = load(char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name)));
                    temp1 = temp1.data;
                end
            elseif contains(subjectfiles(rs).name,'RS2')
                if dataset == "Original" | dataset == "Mike"
                    cfg = [];
                    cfg.dataset = char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name));
                    cfg.demean = 'No';
                    cfg.trials = 'All';
                    temp2    = ft_preprocessing(cfg);
                elseif dataset == "Fieldtrip"
                    temp2 = load(char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name)));
                    temp2 = temp2.data;
                end
            end

        end

        RS1{count} = temp1;
        RS2{count} = temp2;
        count = count+1;

    end


elseif Experiment == 3
    chanlocs = load('/ANTChanlocs.mat');
    Chanlocs = chanlocs.ANTChanlocs;
    folder = '/Exp3EEG/';
    contents = dir(folder);
    dirFlags = [contents.isdir];
    subFolders = contents(dirFlags);
    subjectFolders = {subFolders(4:end).name}; % Start at 3 to skip . and ..
    datafolder = '/EEG/';

    Conditions = readtable('/Exp3HFSdata.xlsx');
    Control = Conditions.participant(Conditions.group == "C");


    count = 1;
    prevname = strings(2,1);
    for i = 1:length(subjectFolders)

        subjectno = subjectFolders(i);
        subjectnoidx = isnumber(subjectno{1});
        subjectno = double(string(subjectno{1}(subjectnoidx)));

        if ~ismember(subjectno,Control)
            continue
        end

        disp(subjectno)

        if dataset == "Original"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*CleanedEpoched*.set'));
        elseif dataset == "Fieldtrip"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*Laplacian_Transformed*.mat'));
        elseif dataset == "Mike"
            subjectfiles = dir(fullfile(folder, subjectFolders{i},'/', '*Laplacian_Transformed_Mike*.set'));
        end

        if isempty(subjectfiles)
            continue
        end

        if prevname(1,1) == ""
            prevname(1,1) = subjectfiles(1).name;
            prevname(2,1) = subjectfiles(1).name;
        else
            prevname(1,1) = prevname(2,1);
            prevname(2,1) = subjectfiles(1).name;

            if prevname(1,1) == prevname(2,1)
                break
            end

        end


        for rs = 1:length(subjectfiles)
            if contains(subjectfiles(rs).name,'RS1')
                if dataset == "Original" | dataset == "Mike"
                    cfg = [];
                    cfg.dataset = char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name));
                    cfg.demean = 'No';
                    cfg.trials = 'All';
                    cfg.continuous   = 'no';
                    temp1    = ft_preprocessing(cfg);
                elseif dataset == "Fieldtrip"
                    temp1 = load(char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name)));
                    temp1 = temp1.data;
                end
            elseif contains(subjectfiles(rs).name,'RS2')
                if dataset == "Original" | dataset == "Mike"
                    cfg = [];
                    cfg.dataset = char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name));
                    cfg.demean = 'No';
                    cfg.trials = 'All';
                    cfg.continuous   = 'no';
                    temp2    = ft_preprocessing(cfg);
                elseif dataset == "Fieldtrip"
                    temp2 = load(char(fullfile(folder, subjectFolders{i},'/',subjectfiles(rs).name)));
                    temp2 = temp2.data;
                end
            end

        end

        RS1{count} = temp1;
        RS2{count} = temp2;
        count = count+1;

    end

end

clearvars -except RS1 RS2 Experiment dataset Chanlocs


%% Now for the transformation and the analysis

for i = 1:length(RS1)
    cfg2 = [];
    cfg2.output  = 'pow';
    cfg2.channel = 'all';
    cfg2.method  = 'mtmfft';
    cfg2.taper   = 'hanning';
    cfg2.foi     = 0:.5:30;
    cfg2.keeptrials  = 'no';
    %     cfg2.trials      = 'all';
    PowspectRS1{i}   = ft_freqanalysis(cfg2, RS1{i});
    PowspectRS2{i}  = ft_freqanalysis(cfg2, RS2{i});
end

% % For plotting
% figure;
% hold on;
% plot(PowspectRS1{1}.freq, PowspectRS1{1}.powspctrm(16,:))
% plot(PowspectRS2{1}.freq, PowspectRS2{1}.powspctrm(16,:))


cfg            = [];
cfg.method     = 'triangulation';
cfg.senstype   = 'EEG';
neighbours = ft_prepare_neighbours(cfg, PowspectRS1{1});

% cfg            = [];
% cfg.neighbours = neighbours;
% cfg.senstype   = 'EEG';
% ft_neighbourplot(cfg, PowspectRS1{1});

cfg = [];
cfg.channel   = 'all';
cfg.latency   = 'all';
cfg.keepindividual = 'no';
cfg.parameter = 'powspctrm';
grandavgRS1  = ft_freqgrandaverage(cfg, PowspectRS1{:});
grandavgRS2  = ft_freqgrandaverage(cfg, PowspectRS2{:});
GAdiff = grandavgRS2.powspctrm - grandavgRS1.powspctrm;


%% For only C3 and C4

% Extract the information
if Experiment == 2
    C3chans = [37,31];
    C4chans = [106,105];
elseif Experiment == 3
    C3chans = find(strcmp({Chanlocs.labels},'C3'));
    C4chans = find(strcmp({Chanlocs.labels},'C4'));
end


[C3RS1,C3RS2,C4RS1,C4RS2] = deal(zeros(size(PowspectRS1,2),length(PowspectRS1{1}.freq)));
for i = 1:length(C3chans)

    C3Pow_RS1 = cellfun(@(x) x.powspctrm(C3chans(i), :), PowspectRS1, 'UniformOutput', false);
    C3RS1 = C3RS1 + cell2mat(C3Pow_RS1');

    C3Pow_RS2 = cellfun(@(x) x.powspctrm(C3chans(i), :), PowspectRS2, 'UniformOutput', false);
    C3RS2 = C3RS2 + cell2mat(C3Pow_RS2');

    C4Pow_RS1 = cellfun(@(x) x.powspctrm(C4chans(i), :), PowspectRS1, 'UniformOutput', false);
    C4RS1 = C4RS1 + cell2mat(C4Pow_RS1');

    C4Pow_RS2 = cellfun(@(x) x.powspctrm(C4chans(i), :), PowspectRS2, 'UniformOutput', false);
    C4RS2 = C4RS2 + cell2mat(C4Pow_RS2');
end

C3RS1 = C3RS1 /i;
C3RS2 = C3RS2 /i;
C4RS1 = C4RS1 /i;
C4RS2 = C4RS2 /i;

RS1 = cat(3,C3RS1,C4RS1);
RS1 = mean(RS1,3);

RS2 = cat(3,C3RS2,C4RS2);
RS2 = mean(RS2,3);

alphaidx = dsearchn(grandavgRS1.freq',[8 12]');
deltaidx = dsearchn(grandavgRS1.freq',[0 4]');

[~,palpha,~,tstats_alpha] = ttest(mean(RS1(:,alphaidx(1):alphaidx(2)),2),mean(RS2(:,alphaidx(1):alphaidx(2)),2),"Tail","left");
alphad = mean(mean(RS2(:,alphaidx(1):alphaidx(2)),2) - mean(RS1(:,alphaidx(1):alphaidx(2)),2))/std(mean(RS2(:,alphaidx(1):alphaidx(2)),2) - mean(RS1(:,alphaidx(1):alphaidx(2)),2));

[~,pdelta,~,tstats_delta] = ttest(mean(RS1(:,deltaidx(1):deltaidx(2)),2),mean(RS2(:,deltaidx(1):deltaidx(2)),2),"Tail","right");
deltad = mean(mean(RS2(:,deltaidx(1):deltaidx(2)),2) - mean(RS1(:,deltaidx(1):deltaidx(2)),2))/std(mean(RS2(:,deltaidx(1):deltaidx(2)),2) - mean(RS1(:,deltaidx(1):deltaidx(2)),2));

avgRS1 = mean(RS1);
avgRS2 = mean(RS2);

powfig = figure(1);
colorSig = [0.5, 0.5, 0.5];
hold on
plot(grandavgRS1.freq,avgRS1,'k-','LineWidth',2)
plot(grandavgRS1.freq,avgRS2,'r-','LineWidth',2)
ylim([0 max(avgRS2)+max(avgRS2)*.5])
xlabel('Frequency (Hz)', 'FontSize', 14) % Adjust x-axis label font size
if dataset == "Fieldtrip"
    ylabel('Power (V^2/m^4/Hz)', 'FontSize', 14) % Adjust y-axis label font size
else
    ylabel('Power (\muV^2)', 'FontSize', 14) % Adjust y-axis label font size
end
title('', 'FontSize', 16) % Adjust title font size
grid on
set(gca, 'FontName', 'Arial', 'FontSize', 20) % Adjust tick label font size
box off
set(gcf,'color','w');
% Alpha Patch
x = [8, 8, 12, 12];
y = [get(gca, 'ylim'), fliplr(get(gca, 'ylim'))];
patch(x, y, colorSig, 'EdgeColor', 'none', 'FaceAlpha', 0.3)
% Delta Patch
x = [0, 0, 4, 4];
y = [get(gca, 'ylim'), fliplr(get(gca, 'ylim'))];
patch(x, y, colorSig, 'EdgeColor', 'none', 'FaceAlpha', 0.3)
legend('Before', 'After','','', 'FontSize', 16) % Adjust legend font size

% figname = strcat('/Figures/','Exp',num2str(Experiment),dataset,'_Powspect','.jpeg');
% saveas( powfig , figname )

%% Compute and plot t values

numelec = size(Chanlocs,2);
numfreq = length(PowspectRS1{1}.freq);

ps = ones(numelec,numfreq);
ts = zeros(numelec,numfreq);

RS1 = zeros(numelec,numfreq,length(PowspectRS1));
RS2 = zeros(numelec,numfreq,length(PowspectRS1));

for participant = 1:length(PowspectRS2)
    RS1(:,:,participant) = PowspectRS1{participant}.powspctrm;
    RS2(:,:,participant) = PowspectRS2{participant}.powspctrm;
end

RS1 = double(RS1);
RS2 = double(RS2);

assert(all(~isnan(RS2(:))), 'RS2 contains NaNs');
assert(all(~isnan(RS1(:))), 'RS1 contains NaNs');

for elec = 1:numelec
    for freq = 1:numfreq

        %         [~,ps(elec,freq),~,stats] = ttest(squeeze(RS1(elec,freq,:)),squeeze(RS2(elec,freq,:)),"Tail","left");
        [~,ps(elec,freq),~,stats] = ttest(squeeze(RS1(elec,freq,:)),squeeze(RS2(elec,freq,:)));
        ts(elec,freq) = stats.tstat;

    end
end


% For plotting of all channels difference after - before
tfig = figure(2);
imagesc(-ts);
colorbar;
ax = gca;
% ax.PlotBoxAspectRatio = [1 1 2]; % Adjust as needed
hold on
colormap(jet)
% Optional: if you want to keep the y-axis ticks centered on each row
if Experiment == 2
    ax.YTick = 1:size(ts, 1);  % Set ticks for every item
    labels = {Chanlocs(:).labels}; % Assuming this is your labels array
    new_labels = repmat({''}, size(labels)); % Create an empty label array of the same size
    new_labels(1:10:end) = labels(1:10:end); % Assign every 10th label
    ax.YTickLabel = new_labels; % Apply new labels to the plot
else
    ax.YTick = 1:size(ts, 1);
    ax.YTickLabel = {Chanlocs(:).labels};
end
ax.XTick = find(mod(grandavgRS1.freq, 5) == 0); % Position ticks
ax.XTickLabel = linspace(0,30,7);
hold off
set(gcf,'color','w');
title('', 'FontSize', 18) % Adjust title font size
ylabel('Electrode Label','FontSize', 20)
xlabel('Frequency (Hz)','FontSize', 20)
caxis([-3 3])

figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_T_Values','.jpeg');
saveas( tfig , figname )

%% Spatio-Frequency test
foi_contrast = [0 30];
tail = 1;
cfg = [];
cfg.channel          = 'all';
cfg.frequency        = foi_contrast;
% cfg.avgoverfreq      = 'yes';
% cfg.avgoverchan = 'yes';
cfg.parameter        = 'powspctrm';
cfg.method           = 'ft_statistics_montecarlo';  % use the Monte Carlo method to calculate probabilities
cfg.statistic        = 'ft_statfun_depsamplesT';    % use the dependent samples T-statistic as a measure to evaluate the effect at each sample
cfg.correctm         = 'cluster';
cfg.clusteralpha     = 0.05;                        % threshold for the sample-specific test, is used for thresholding
cfg.clusterstatistic = 'maxsum';
cfg.clusterthreshold = 'nonparametric_common';
cfg.minnbchan        = 2;                           % minimum number of neighbouring channels that is required
cfg.tail             = tail;                           % test the left, right or both tails of the distribution
cfg.clustertail      = tail;
cfg.alpha            = 0.05;                        % alpha level of the permutation test
cfg.correcttail      = 'alpha';                     % see https://www.fieldtriptoolbox.org/faq/why_should_i_use_the_cfg.correcttail_option_when_using_statistics_montecarlo/
cfg.computeprob      = 'yes';
cfg.numrandomization = 5000;                         % number of random permutations
cfg.neighbours       = neighbours;                  % the neighbours for each sensor to form clusters

nsubj                     = length(PowspectRS1);
design                    = zeros(2,2*nsubj);
design(1,1:nsubj)         = 1;
design(1,nsubj+1:2*nsubj) = 2;
design(2,1:nsubj)         = 1:nsubj;
design(2,nsubj+1:2*nsubj) = 1:nsubj;
cfg.design   = design; % design matrix
cfg.ivar     = 1;      % the 1st row codes the independent variable (sedation level)
cfg.uvar     = 2;      % the 2nd row codes the unit of observation (subject)
[stat] = ft_freqstatistics(cfg, PowspectRS2{:},PowspectRS1{:});

%% Plot the results of the test (significant positive or negative clusters)

% elec = PowspectRS1{1}.elec;
% 
% if  isfield(stat,'posclusters')
%     posclusts = find([stat.posclusters.prob] < stat.cfg.alpha);
% end
% 
% if isfield(stat,'negclusters')
%     negclusts = find([stat.negclusters.prob] < stat.cfg.alpha);
% end
% 
% 
% for i = 1:length(negclusts)
% 
%     signegmask = (stat.negclusterslabelmat==negclusts(i));
%     grandavgRS1.mask = signegmask;
%     grandavgRS2.mask = signegmask;
% 
%     cfg = [];
%     cfg.xlim          = foi_contrast;
%     cfg.elec          = elec;
%     cfg.colorbar      = 'no';
%     cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
%     cfg.maskstyle     = 'box';
%     cfg.parameter     = 'powspctrm';
%     cfg.maskfacealpha = 0.5;
%     cfg.title         = ['Negative Cluster ', num2str(negclusts(i))];
%     figure;
%     ft_multiplotER(cfg, grandavgRS1, grandavgRS2);
% 
% end
% 
% for i = 1:length(posclusts)
% 
%     sigposmask = (stat.posclusterslabelmat==posclusts(i));
%     grandavgRS1.mask = sigposmask;
%     grandavgRS2.mask = sigposmask;
% 
%     cfg = [];
%     cfg.xlim          = foi_contrast;
%     cfg.elec          = PowspectRS1{1}.elec;
%     cfg.colorbar      = 'no';
%     cfg.maskparameter = 'mask';  % use the thresholded probability to mask the data
%     cfg.maskstyle     = 'box';
%     cfg.parameter     = 'powspctrm';
%     cfg.maskfacealpha = 0.5;
%     cfg.title         = ['Positive Cluster ', num2str(posclusts(i))];
%     figure;
%     ft_multiplotER(cfg, grandavgRS1, grandavgRS2);
% 
% end
% 
% cfg = [];
% cfg.alpha     = stat.cfg.alpha;
% cfg.parameter = 'stat';
% cfg.zlim      = [-3 3];
% cfg.highlightsymbolseries = ['*', '*', '+', 'o', '.']; % 1x5 vector, highlight marker symbol series (default ['*', 'x', '+', 'o', '.'] for p < [0.01 0.05 0.1 0.2 0.3]
% cfg.highlightcolorpos = [1 0 0];
% cfg.highlightcolorneg = [0 1 1];
% cfg.toi       = 'all';
% cfg.elec      = elec;
% ft_clusterplot(cfg, stat);


%% Custom plotting

elec = PowspectRS1{1}.elec;
if  isfield(stat,'posclusters')
    posclusts = find([stat.posclusters.prob] < stat.cfg.alpha);
else
    posclusts = [];
end

if isfield(stat,'negclusters')
    negclusts = find([stat.negclusters.prob] < stat.cfg.alpha);
else
    negclusts = [];
end

if posclusts
    sigposmask = (stat.posclusterslabelmat==posclusts(1));
    tempRS1 = zeros(1,length(PowspectRS1));
    tempRS2 = zeros(1,length(PowspectRS1));

    for i = 1:length(PowspectRS1)
        tempRS1(i) = mean(PowspectRS1{i}.powspctrm(sigposmask));
        tempRS2(i) = mean(PowspectRS2{i}.powspctrm(sigposmask));
    end
    poseff = mean(tempRS2-tempRS1)/std(tempRS2-tempRS1);
end


if negclusts
    signegmask = (stat.negclusterslabelmat==negclusts(1));
    tempRS1 = zeros(1,length(PowspectRS1));
    tempRS2 = zeros(1,length(PowspectRS1));
    for i = 1:length(PowspectRS1)
        tempRS1(i) = mean(PowspectRS1{i}.powspctrm(signegmask));
        tempRS2(i) = mean(PowspectRS2{i}.powspctrm(signegmask));
    end
    negeff = mean(tempRS2-tempRS1)/std(tempRS2-tempRS1);
end
clear tempRS1 tempRS2


colourlim = [-3 3];

for i = 1:length(negclusts)

    signegmask = (stat.negclusterslabelmat==negclusts(i));
    sigfreqs = grandavgRS1.freq(logical(mean(signegmask,1)));
    sigelecs = logical(mean(signegmask,2));
    [n_rows, n_cols, freq_groups] = optimize_subplot_layout(sigfreqs);


    % Plotting
    negclustfig = figure('Position', [100, 100, 300*n_cols, 200*n_rows]);
    for j = 1:length(freq_groups)
        subplot(n_rows, n_cols, j);
        freq_group = freq_groups{j};

        if length(freq_group) == 1
            mask = signegmask(:,grandavgRS2.freq==freq_group);
            dat = -ts(:,grandavgRS2.freq==freq_group);
            plot_single_frequency(Chanlocs, freq_group, mask, dat, true, colourlim);
        else
            if ~isempty(freq_group)
                mask = signegmask(:,find(grandavgRS2.freq==freq_group(1)):find(grandavgRS2.freq==freq_group(2)));
                dat = -ts(:,find(grandavgRS2.freq==freq_group(1)):find(grandavgRS2.freq==freq_group(2)));
                plot_frequency_group(Chanlocs, freq_group, mask, dat, true, colourlim);
            end
        end
    end
    % Adjust the layout
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Negclust','.jpeg');
    saveas( negclustfig , figname )

end


for i = 1:length(posclusts)

    sigposmask = (stat.posclusterslabelmat==posclusts(i));
    sigfreqs = grandavgRS1.freq(logical(mean(sigposmask,1)));
    sigelecs = logical(mean(sigposmask,2));
    [n_rows, n_cols, freq_groups] = optimize_subplot_layout(sigfreqs);

    % Plotting
    posclustfig = figure('Position', [100, 100, 300*n_cols, 200*n_rows]);
    for j = 1:length(freq_groups)
        subplot(n_rows, n_cols, j);
        freq_group = freq_groups{j};

        if length(freq_group) == 1
            mask = sigposmask(:,grandavgRS2.freq==freq_group);
            dat = -ts(:,grandavgRS2.freq==freq_group);
            plot_single_frequency(Chanlocs, freq_group, mask, dat, true, colourlim);
        else
            if ~isempty(freq_group)
                mask = sigposmask(:,find(grandavgRS2.freq==freq_group(1)):find(grandavgRS2.freq==freq_group(2)));
                dat = -ts(:,find(grandavgRS2.freq==freq_group(1)):find(grandavgRS2.freq==freq_group(2)));
                plot_frequency_group(Chanlocs, freq_group, mask, dat, true, colourlim);
            end
        end
    end
    % Adjust the layout
    set(gcf, 'Units', 'Normalized', 'OuterPosition', [0, 0.04, 1, 0.96]);
    figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Posclust','.jpeg');
    saveas( posclustfig , figname )

end




%% Stress and Fear analysis

if  isfield(stat,'posclusters')
    posclusts = find([stat.posclusters.prob] < stat.cfg.alpha);
else
    posclusts = [];
end

if isfield(stat,'negclusters')
    negclusts = find([stat.negclusters.prob] < stat.cfg.alpha);
else
    negclusts = [];
end


if Experiment == 2
    Intensity = readtable("Intensity.xlsx");
    Intensity = Intensity(Intensity.Condition == "Alone",:);
    exclude = string(Intensity.ParticipantID) == 'SS25';
    Intensity = Intensity(~exclude, :);

    Positive_Slopes = cell(size(posclusts));
    Positive_P_values = cell(size(posclusts));
    Positive_Frequencies = cell(size(posclusts));

    for pos = 1:length(posclusts)
        sigposmask = (stat.posclusterslabelmat == posclusts(pos));
        sigelec = logical(sum(sigposmask, 2));
        sigFreqs = find(logical(sum(sigposmask, 1)));
        slopes = nan(length(sigFreqs),2);
        pvals = nan(length(sigFreqs),2);
        for f = 1:length(sigFreqs)
            Freq = PowspectRS2{1}.freq(sigFreqs(f));
            Intensity.PowerDiff = nan(height(Intensity), 1);
            allsubs = unique(Intensity.ParticipantID);
            for i = 1:length(allsubs)
                subject = allsubs{i};
                for j = 1:length(PowspectRS1)
                    if contains(PowspectRS2{j}.cfg.previous.dataset, subject,'IgnoreCase',true)
                        ind = dsearchn(PowspectRS2{1}.freq', Freq);
                        diff = mean(PowspectRS2{j}.powspctrm(sigelec, ind) - PowspectRS1{j}.powspctrm(sigelec, ind));
                        Intensity.PowerDiff(string(Intensity.ParticipantID) == subject) = diff;
                        break;
                    end
                end
            end
            % Fit the models
            Intstress = Intensity(1:40:height(Intensity),:);
            lm = fitlm(Intstress,'Stress ~ PowerDiff');
            lme = fitlme(Intensity,'Ratings ~ T0 + Arm*PowerDiff + (1|ParticipantID)');
            % Save the results
            slopes(f,1) = lme.Coefficients(5,2).Estimate; % Insert result of mixed model analysis here
            pvals(f,1) = lme.Coefficients(5,6).pValue; % Insert result of mixed model analysis here

            slopes(f,2) = lm.Coefficients(2,1).Estimate; % Insert result of mixed model analysis here
            pvals(f,2) = lm.Coefficients(2,4).pValue;

        end
        Positive_Slopes{pos} = slopes;
        Positive_P_values{pos} = pvals;
        Positive_Frequencies{pos} = PowspectRS2{1}.freq(sigFreqs);
    end

    % For negative clusters
    Negative_Slopes = cell(size(negclusts));
    Negative_P_values = cell(size(negclusts));
    Negative_Frequencies = cell(size(negclusts));

    for neg = 1:length(negclusts)
        signegmask = (stat.negclusterslabelmat == negclusts(neg));
        sigelec = logical(sum(signegmask, 2));
        sigFreqs = find(logical(sum(signegmask, 1)));
        Intensity.PowerDiff = nan(height(Intensity), 1);
        allsubs = unique(Intensity.ParticipantID);
        slopes = nan(length(sigFreqs),1);
        pvals = nan(length(sigFreqs),1);
        for f = 1:length(sigFreqs)
            Freq = PowspectRS2{1}.freq(sigFreqs(f));

            % Extract and build up the data for power difference
            Intensity.PowerDiff = nan(height(Intensity), 1);
            allsubs = unique(Intensity.ParticipantID);
            for i = 1:length(allsubs)
                subject = allsubs{i};
                for j = 1:length(PowspectRS1)
                    if contains(PowspectRS2{j}.cfg.previous.dataset, subject,'IgnoreCase',true)
                        ind = dsearchn(PowspectRS2{1}.freq', Freq);
                        diff = mean(PowspectRS2{j}.powspctrm(sigelec, ind) - PowspectRS1{j}.powspctrm(sigelec, ind));
                        Intensity.PowerDiff(string(Intensity.ParticipantID) == subject) = diff;
                        break;
                    end
                end

            end

            % Fit the models
            Intstress = Intensity(1:40:height(Intensity),:);
            lm = fitlm(Intstress,'Stress ~ PowerDiff');
            lme = fitlme(Intensity,'Ratings ~ T0 + Arm*PowerDiff + (1|ParticipantID)');

            % Save the results
            slopes(f,1) = lme.Coefficients(5,2).Estimate; % Insert result of mixed model analysis here
            pvals(f,1) = lme.Coefficients(5,6).pValue; % Insert result of mixed model analysis here

            slopes(f,2) = lm.Coefficients(2,1).Estimate; % Insert result of mixed model analysis here
            pvals(f,2) = lm.Coefficients(2,4).pValue;

            
        end
        Negative_Slopes{neg} = slopes;
        Negative_P_values{neg} = pvals;
        Negative_Frequencies{neg} = PowspectRS2{1}.freq(sigFreqs);

    end    

    % Now plot
    for clust = 1:length(posclusts)
        posclustfig = figure; set(gcf,'color','w');
        subplot(211)
        plot(Positive_Frequencies{clust},Positive_Slopes{clust}(:,1),'k-','LineWidth',2)
        title('coefficients by Frequency','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
        ylabel('Unstandardised Coefficient','FontSize',14)
        subplot(212)
        plot(Positive_Frequencies{clust},Positive_P_values{clust}(:,1),'k-','LineWidth',2)
        title('P-values by Frequency','FontSize',14)
        yline(0.05, 'r-', 'LineWidth', 2)
        legend('','Threshold: .05')
        xlabel('Frequency (Hz)','FontSize',14)
        ylabel('P-Value','FontSize',14)
%         subplot(122)
%         plot(Positive_Frequencies{clust},Positive_Slopes{clust}(:,2),'LineWidth',2)
%         title('coefficients for Stress')
%         xlabel('Frequency (Hz)', 'FontSize',14)
%         ylabel('Slope', 'FontSize',14)
%         subplot(224)
%         plot(Positive_Frequencies{clust},Positive_P_values{clust}(:,2),'LineWidth',2)
%         yline(0.05, 'r-', 'LineWidth', 2)
%         title('P-values for Stress')
%         xlabel('Frequency (Hz)')
%         ylabel('P-Value')
        sgtitle(strcat('Positive cluster ', num2str(clust)))
        figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Posclust_Prediction','.jpeg');
        saveas( posclustfig , figname )
    end

        % Now plot
    for clust = 1:length(negclusts)
        negclustfig = figure; set(gcf,'color','w');
        subplot(211)
        plot(Negative_Frequencies{clust},Negative_Slopes{clust}(:,1),'k-','LineWidth',2)
        title('coefficients by frequency','FontSize',14)
        ylabel('Slope','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
%         subplot(222)
%         plot(Negative_Frequencies{clust},Negative_Slopes{clust}(:,2),'LineWidth',2)
%         title('coefficients for Stress')
%         ylabel('Slope')
%         xlabel('Frequency (Hz)')
        subplot(212)
        plot(Negative_Frequencies{clust},Negative_P_values{clust}(:,1),'k-','LineWidth',2)
        title('P-values by Frequency','FontSize',14)
        yline(0.05, 'r-', 'LineWidth', 2)
        legend('','Threshold: .05')
        ylabel('P-Value','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
%         subplot(224)
%         plot(Negative_Frequencies{clust},Negative_P_values{clust}(:,2),'LineWidth',2)
%         yline(0.05, 'r-', 'LineWidth', 2)
%         title('P-values for Stress')
%         ylabel('P-Value')
%         xlabel('Frequency (Hz)')
        sgtitle(strcat('Negative cluster ', num2str(clust)))
        figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Negclust_Prediction','.jpeg');
        saveas( negclustfig , figname )
    end


elseif Experiment == 3
    Intensity = readtable("Intensity.xls");
    Intensity = Intensity(Intensity.Condition == "C",:);

    Positive_Slopes = cell(size(posclusts));
    Positive_P_values = cell(size(posclusts));
    Positive_Frequencies = cell(size(posclusts));

    for pos = 1:length(posclusts)
        sigposmask = (stat.posclusterslabelmat == posclusts(pos));
        sigelec = logical(sum(sigposmask, 2));
        sigFreqs = find(logical(sum(sigposmask, 1)));
        slopes = nan(length(sigFreqs),2);
        pvals = nan(length(sigFreqs),2);
        for f = 1:length(sigFreqs)
            Freq = PowspectRS2{1}.freq(sigFreqs(f));
            Intensity.PowerDiff = nan(height(Intensity), 1);
            allsubs = unique(Intensity.ParticipantID);


            count = 1;
            for i = 1:length(allsubs)
                subject = allsubs{i}(1:end-4);
                for j = 1:length(PowspectRS1)
                    if contains(PowspectRS2{j}.cfg.previous.dataset, subject, 'IgnoreCase',true)
                        temp(count,1) = string(subject);
                        temp(count,2) = string(PowspectRS2{j}.cfg.previous.dataset);
                        count = count+1;
                        ind = dsearchn(PowspectRS2{1}.freq', Freq);
                        diff = mean(PowspectRS2{j}.powspctrm(sigelec, ind) - PowspectRS1{j}.powspctrm(sigelec, ind));
                        Intensity.PowerDiff(string(Intensity.ParticipantID) == allsubs{i}) = diff;
                    end
                end
            end


            % Fit the models
            Intstress = Intensity(1:40:height(Intensity),:);
            lm = fitlm(Intstress,'Fear ~ PowerDiff');
            lme = fitlme(Intensity,'IntensityRatings ~ T0 + Arm*PowerDiff + (1|ParticipantID)');
            % Save the results
            slopes(f,1) = lme.Coefficients(5,2).Estimate; % Insert result of mixed model analysis here
            pvals(f,1) = lme.Coefficients(5,6).pValue; % Insert result of mixed model analysis here

            slopes(f,2) = lm.Coefficients(2,1).Estimate; % Insert result of mixed model analysis here
            pvals(f,2) = lm.Coefficients(2,4).pValue;

        end
        Positive_Slopes{pos} = slopes;
        Positive_P_values{pos} = pvals;
        Positive_Frequencies{pos} = PowspectRS2{1}.freq(sigFreqs);
    end

    % For negative clusters
    Negative_Slopes = cell(size(negclusts));
    Negative_P_values = cell(size(negclusts));
    Negative_Frequencies = cell(size(negclusts));

    for neg = 1:length(negclusts)
        signegmask = (stat.negclusterslabelmat == negclusts(neg));
        sigelec = logical(sum(signegmask, 2));
        sigFreqs = find(logical(sum(signegmask, 1)));
        Intensity.PowerDiff = nan(height(Intensity), 1);
        allsubs = unique(Intensity.ParticipantID);
        slopes = nan(length(sigFreqs),1);
        pvals = nan(length(sigFreqs),1);
        for f = 1:length(sigFreqs)
            Freq = PowspectRS2{1}.freq(sigFreqs(f));
            Intensity.PowerDiff = nan(height(Intensity), 1);
            allsubs = unique(Intensity.ParticipantID);
            for i = 1:length(allsubs)
                subject = allsubs{i}(1:end-4);
                for j = 1:length(PowspectRS1)
                    if contains(PowspectRS2{j}.cfg.previous.dataset, subject, 'IgnoreCase',true)
                        ind = dsearchn(PowspectRS2{1}.freq', Freq);
                        diff = mean(PowspectRS2{j}.powspctrm(sigelec, ind) - PowspectRS1{j}.powspctrm(sigelec, ind));
                        Intensity.PowerDiff(string(Intensity.ParticipantID) == allsubs{i}) = diff;
                    end
                end

            end

            % Fit the models
            Intstress = Intensity(1:20:height(Intensity),:);
            lm = fitlm(Intstress,'Fear ~ PowerDiff');
            lme = fitlme(Intensity,'IntensityRatings ~ T0 + Arm*PowerDiff + (1|ParticipantID)');

            % Save the results
            slopes(f,1) = lme.Coefficients(5,2).Estimate; % Insert result of mixed model analysis here
            pvals(f,1) = lme.Coefficients(5,6).pValue; % Insert result of mixed model analysis here

            slopes(f,2) = lm.Coefficients(2,1).Estimate; % Insert result of mixed model analysis here
            pvals(f,2) = lm.Coefficients(2,4).pValue;

            
        end
        Negative_Slopes{neg} = slopes;
        Negative_P_values{neg} = pvals;
        Negative_Frequencies{neg} = PowspectRS2{1}.freq(sigFreqs);

    end    

    % Now plot
    for clust = 1:length(posclusts)
        posclustfig = figure; set(gcf,'color','w');
        subplot(211)
        plot(Positive_Frequencies{clust},Positive_Slopes{clust}(:,1),'k-','LineWidth',2)
        title('coefficients by Frequency','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
        ylabel('Unstandardised Coefficient','FontSize',14)
        subplot(212)
        plot(Positive_Frequencies{clust},Positive_P_values{clust}(:,1),'k-','LineWidth',2)
        title('P-values by Frequency','FontSize',14)
        yline(0.05, 'r-', 'LineWidth', 2)
        legend('','Threshold: .05')
        xlabel('Frequency (Hz)','FontSize',14)
        ylabel('P-Value','FontSize',14)
%         subplot(122)
%         plot(Positive_Frequencies{clust},Positive_Slopes{clust}(:,2),'LineWidth',2)
%         title('coefficients for Stress')
%         xlabel('Frequency (Hz)', 'FontSize',14)
%         ylabel('Slope', 'FontSize',14)
%         subplot(224)
%         plot(Positive_Frequencies{clust},Positive_P_values{clust}(:,2),'LineWidth',2)
%         yline(0.05, 'r-', 'LineWidth', 2)
%         title('P-values for Stress')
%         xlabel('Frequency (Hz)')
%         ylabel('P-Value')
        sgtitle(strcat('Positive cluster ', num2str(clust)))
        figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Posclust_Prediction','.jpeg');
        saveas( posclustfig , figname )
    end

        % Now plot
    for clust = 1:length(negclusts)
        negclustfig = figure; set(gcf,'color','w');
        subplot(211)
        plot(Negative_Frequencies{clust},Negative_Slopes{clust}(:,1),'k-','LineWidth',2)
        title('coefficients by frequency','FontSize',14)
        ylabel('Slope','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
%         subplot(222)
%         plot(Negative_Frequencies{clust},Negative_Slopes{clust}(:,2),'LineWidth',2)
%         title('coefficients for Stress')
%         ylabel('Slope')
%         xlabel('Frequency (Hz)')
        subplot(212)
        plot(Negative_Frequencies{clust},Negative_P_values{clust}(:,1),'k-','LineWidth',2)
        title('P-values by Frequency','FontSize',14)
        yline(0.05, 'r-', 'LineWidth', 2)
        legend('','Threshold: .05')
        ylabel('P-Value','FontSize',14)
        xlabel('Frequency (Hz)','FontSize',14)
%         subplot(224)
%         plot(Negative_Frequencies{clust},Negative_P_values{clust}(:,2),'LineWidth',2)
%         yline(0.05, 'r-', 'LineWidth', 2)
%         title('P-values for Stress')
%         ylabel('P-Value')
%         xlabel('Frequency (Hz)')
        sgtitle(strcat('Negative cluster ', num2str(clust)))
        figname = strcat('/Alpha_Laplacian/Manuscript/Figures/','Exp',num2str(Experiment),dataset,'_Negclust_Prediction','.jpeg');
        saveas( negclustfig , figname )
    end

end





