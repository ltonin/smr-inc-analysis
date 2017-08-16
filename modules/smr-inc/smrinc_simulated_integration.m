% clearvars; clc; 
% 
% subject     = 'b4';
targetdir   = 'analysis/';

% Load posterior probabilities
cfilepath = [targetdir subject '_simulated_raw.mat'];
util_bdisp(['[io] - Loading posterior probabilities for subject ' subject ': ' cfilepath]);
data = load(cfilepath);

% Getting posterior probabilities
pp = data.pp(:, 1);

% Getting events
labels = data.labels;
events = data.events;

% Getting labels
Rk             = data.labels.Rk;
Runs           = unique(Rk);
NumRuns        = length(Runs);
Dk             = data.labels.Dk;
Days           = unique(Dk);
NumDays        = length(Days);
Ik             = data.labels.Ik;
Integrators    = unique(Ik);
NumIntegrators = length(Integrators);
Mk             = data.labels.Mk;
Modalities     = unique(Mk);
NumModalities  = length(Modalities);

% Getting integrator parameters
integrator = data.integrator;

NumSamples = size(pp, 1);

% Extracting continuous feedback events
[Cfbk, CfbEvents] = proc_get_event2(781, NumSamples, events.POS, events.TYP, events.DUR);
[~, CueEvents] = proc_get_event2([769 770 771 773 783], NumSamples, events.POS, events.TYP, events.DUR);
[~, ResEvents] = proc_get_event2([897 898], NumSamples, events.POS, events.TYP, events.DUR);
CueTrials = CueEvents.TYP;
NumTrials = length(CueTrials);

Ck = Cfbk;
Xk = Cfbk;
Tk = Cfbk;
for trId = 1:NumTrials
    cstart = CfbEvents.POS(trId);
    cstop  = cstart + CfbEvents.DUR(trId) - 1;
    ccue   = CueTrials(trId);
    cres   = ResEvents.TYP(trId);
    crun   = Rk(cstart);
    if(ccue ~= 783)
        cintegrator = integrator{crun};
        ctargets = [unique(cintegrator.thresholds) 1-unique(cintegrator.thresholds)];
        ctar = ctargets(cintegrator.classes == ccue);
    else
        ctar = 0;
    end
    
    Ck(cstart:cstop) = ccue;
    Xk(cstart:cstop) = cres;
    Tk(cstart:cstop) = ctar;
end

%% Apply integration for each run
disp('[proc] - Applying integration foreach run');
ema_pp = 0.5*ones(NumSamples, 1);
dyn_pp = 0.5*ones(NumSamples, 1);
for rId = 1:NumRuns
    cstart = find(Rk == Runs(rId), 1, 'first'); 
    cstop  = find(Rk == Runs(rId), 1, 'last'); 
    cintegrator = integrator{rId};
    
    if(cintegrator.type == 1)    % ema
        alpha     = cintegrator.alpha;
        rejection = cintegrator.rejection;
        for sId = cstart+1:cstop

            yp = ema_pp(sId-1);
            x  = pp(sId);
            ema_pp(sId) = smrinc_integrator_ema(x, yp, alpha, rejection);
            
            if( isempty(find(CfbEvents.POS == sId, 1)) == false)
                ema_pp(sId) = 0.5;
            end
        end
    elseif(cintegrator.type == 2)    % ema
        phi    = cintegrator.phi;
        chi    = cintegrator.chi;
        inc    = cintegrator.inc;
        nrpt   = cintegrator.nrpt;
        bias   = cintegrator.bias;
        degree = cintegrator.degree;
        coeff  = smrinc_integrator_forceprofile(inc, nrpt, bias, degree);
        
        for sId = cstart+1:cstop

            yp = dyn_pp(sId-1);
            x  = pp(sId);
            dyn_pp(sId) = smrinc_integrator_dynamic(x, yp, coeff, phi, chi, 0.0625);      
            
            if( isempty(find(CfbEvents.POS == sId, 1)) == false)
                dyn_pp(sId) = 0.5;
            end
        end
    end
end

%% Saving data
targetname = [targetdir subject '_simulated_integrated.mat'];
util_bdisp(['[out] - Saving integrated probabilities in ' targetname]);
save(targetname, 'pp', 'ema_pp', 'dyn_pp', 'Tk', 'Ck', 'Ik', 'Xk', 'Mk', 'Rk', 'Dk', 'events', 'labels');

%% Exporting text file
textfilename = [targetdir subject '_simulated_probabilities.txt'];
util_bdisp(['[out] - Exporting integrated probabilities to ' targetname]);
fid = fopen(textfilename, 'w+t');
ToBeStored = [(1:NumSamples)', pp, ema_pp, dyn_pp, Tk, Ck, Ik, Xk, Mk, Rk, Dk];
if(fid ~= -1)
    fprintf(fid, '%8s\t%7s\t%7s\t%7s\t%7s\t%5s\t%5s\t%5s\t%5s\t%5s\t%5s\n', 'sample', 'pp', 'ema', 'dyn', 'Tk', 'Ck', 'Ik', 'Xk', 'Mk', 'Rk', 'Dk');
    fprintf(fid, '%8d\t%7.4f\t%7.4f\t%7.4f\t%7.4f\t%5d\t%5d\t%5d\t%5d\t%5d\t%5d\n', ToBeStored');
else
    error('chk:fid', ['Cannot create the file: ' textfilename]);
end
fclose(fid);