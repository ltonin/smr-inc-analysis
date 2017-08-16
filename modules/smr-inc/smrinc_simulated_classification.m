% clearvars; clc; 
% 
% subject     = 'x3';
pattern     = 'online';
extension   = '.mat';
targetdir   = 'analysis/';

%% Loading data

util_bdisp(['[io] - Loading data for subject ' subject]);

% Concatenating data
[psd, events, labels, settings] = smrinc_concatenate_data(targetdir, subject, pattern, extension);

% Getting data information
NumSamples     = size(psd, 1);
NumChannels    = size(psd, 3);
Rk             = labels.Rk;
Runs           = unique(Rk);
NumRuns        = length(Runs);

% Reshaping PSD and applying log    
F = proc_reshape_ts_bc(log(psd));

% Initialize variables
pp   = 0.5*ones(NumSamples, 2);
classifier = cell(NumRuns, 1);
integrator = cell(NumRuns, 1);

% Computing raw classification probabilities
util_bdisp(['[proc] - Computing raw probabilities for ' num2str(NumRuns) ' runs']);
for rId = 1:NumRuns 
    
    % Getting sample index for each online run
    cstart = find(Rk == rId, 1, 'first');
    cstop  = find(Rk == rId, 1, 'last');
    
    % Getting classifier used in this run
    if(strcmpi(settings{rId}.info.modality, 'online'))
        cclassifiername = [targetdir settings{rId}.log.classifier];
        disp(['[io] - Loading classifier for run ' num2str(rId) ': ' cclassifiername])
        classifier{rId} = load(cclassifiername);
    else
        continue;
    end
    
    % Getting log information for the run
    loginfo = settings{rId}.log;
    integrator{rId}.classes = classifier{rId}.analysis.settings.task.classes_old;
    for cId = 1:size(integrator{rId}.classes, 2)
        integrator{rId}.thresholds(cId) = str2double(loginfo.(['th_' num2str(integrator{rId}.classes(cId))]));
    end
    
    integrator{rId}.type = util_cellfind({loginfo.integrator}, labels.Il)-1;
    switch(loginfo.integrator)
        case 'ema'
            integrator{rId}.rejection = str2double(loginfo.rejection);
            integrator{rId}.alpha     = str2double(loginfo.alpha);
        case 'dynamic'
            integrator{rId}.phi    = str2double(loginfo.phi);
            integrator{rId}.chi    = str2double(loginfo.chi);
            integrator{rId}.bias   = str2double(loginfo.bias);
            integrator{rId}.inc    = str2double(loginfo.inc);
            integrator{rId}.nrpt   = str2double(loginfo.nrpt);
            integrator{rId}.degree = str2double(loginfo.degree);
    end
            
    % Importing feature indexes used by the classifier
    FeatureIdx = smrinc_feature2index(classifier{rId}.analysis.tools.features.bands, settings{rId}.spectrogram.freqgrid, 1:NumChannels);
    GauClassifier = classifier{rId}.analysis.tools.net.gau;
    
    % Evaluate classifier
    disp('[proc] - Evaluate classifier');
    for tId = cstart:cstop
        [~, pp(tId, :)] = gauClassifier(GauClassifier.M, GauClassifier.C, F(tId, FeatureIdx));
    end 
end

%% Saving data
targetname = [targetdir subject '_simulated_raw.mat'];
util_bdisp(['[out] - Saving raw probabilities in ' targetname]);
save(targetname, 'pp', 'integrator', 'classifier', 'events', 'labels');