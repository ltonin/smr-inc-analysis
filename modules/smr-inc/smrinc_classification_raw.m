clearvars; clc; 

subject     = 'ah7';
pattern     = 'mi_bhbf';
extension   = '.mat';
datapath    = '/mnt/data/Research/smr-inc/';
targetdir   = 'analysis/';


%% Loading data

util_bdisp(['[io] - Loading data for subject ' subject]);

% Concatenating data
[psd, events, labels, settings] = smrinc_concatenate_data(targetdir, subject, pattern, extension);
nsamples = size(psd, 1);

% Retrieving log file
loginfo = smrinc_import_log(logfile);


% Generate event labels
[~, CfbEvents] = proc_get_event2(781, nsamples, events.POS, events.TYP, events.DUR);
[~, CueEvents] = proc_get_event2([771 773 783], nsamples, events.POS, events.TYP, events.DUR);
ntrials = length(CfbEvents.TYP);
    
    
    F = log(psd);