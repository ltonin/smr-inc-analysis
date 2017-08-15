clearvars; clc;

sublist     = {'ah7', 'o8', 'ai2', 'b4', 'e8', 'g6', 'x3'};
nsubjects   = length(sublist);

pattern     = 'mi';
extension   = '.gdf';
datapath    = '/mnt/data/Research/smr-inc/';
targetdir   = 'analysis/';

%% Processing parameters
mlength    = 1;
wlength    = 0.5;
pshift     = 0.25;                  
wshift     = 0.0625;                
selfreqs   = 4:2:48;
selchans   = 1:16;                  % <-- Needed for the 2-amplifiers setup
load('extra/laplacian16.mat');     

winconv = 'backward';               % Type of conversion for events from samples to psd windows

%% Create/Check for savepath
[~, savepath] = util_mkdir(pwd, targetdir);

%% Compute spectrogram for all subjects
for sId = 1:nsubjects
    util_bdisp(['[io] - Subject ' num2str(sId) '/' num2str(nsubjects) ': ' sublist{sId}]);
    
    % Get data
    [Files, Folders] = util_getdata(datapath, sublist{sId}, pattern, extension);
    nfiles = length(Files);
    
    % Processing files
    for fId = 1:nfiles
        cfilename = Files{fId};
        util_bdisp(['[io] - Loading file ' num2str(fId) '/' num2str(nfiles)]);
        disp(['       File: ' cfilename]);
    
        % Get information from filename
        cinfo = util_getfile_info(cfilename);
     
        % Importing gdf file
        [s, h] = sload(cfilename);
        
        s = s(:, selchans);         
    
        % Computed DC removal
        s_dc = s-repmat(mean(s),size(s,1),1);

        % Compute Spatial filter
        s_lap = s_dc*lap;

        % Compute spectrogram
        [psd, freqgrid] = proc_spectrogram(s_lap, wlength, wshift, pshift, h.SampleRate, mlength);

        % Selecting desired frequencies
        [freqs, idfreqs] = intersect(freqgrid, selfreqs);
        psd = psd(:, idfreqs, :);
        
        % Extract events
        cevents     = h.EVENT;
        
        events.TYP = cevents.TYP;
        events.POS = proc_pos2win(cevents.POS, wshift*h.SampleRate, winconv, mlength*h.SampleRate);
        events.DUR = floor(cevents.DUR/(wshift*h.SampleRate)) + 1;
        events.conversion = winconv;
        
        % Create settings structure
        settings.data.filename          = cfilename;
        settings.data.nsamples          = size(s, 1);
        settings.data.nchannels         = size(s, 2);
        settings.data.samplerate        = h.SampleRate;
        settings.spatial.laplacian      = lap;
        settings.spectrogram.wlength    = wlength;
        settings.spectrogram.wshift     = wshift;
        settings.spectrogram.pshift     = pshift;
        settings.spectrogram.freqgrid   = freqs;
        settings.spectrogram.winconv    = winconv;
        settings.info                   = cinfo;

        % Retrieving log information
        settings.log = smrinc_import_log(cfilename);
        
        [~, name] = fileparts(cfilename);
        sfilename = [savepath '/' name '.mat'];
        util_bdisp(['[out] - Saving psd in: ' sfilename]);
        save(sfilename, 'psd', 'freqs', 'events', 'settings'); 
    end 
end