clearvars; clc; 

subject     = 'b4';
targetdir   = 'analysis/';

% Load posterior probabilities
cfilepath = [targetdir subject '_probabilities_raw.mat'];
disp(['[io] - Loading posterior probabilities for subject ' subject ': ' cfilepath]);
data = load(cfilepath);

% Getting posterior probabilities
pp = data.pp(:, 1);

% Getting events
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

% Getting integrator parameters
integrator = data.integrator;

NumSamples = size(pp, 1);

% Extracting continuous feedback events
[~, CfbEvents] = proc_get_event2(781, NumSamples, events.POS, events.TYP, events.DUR);
[~, CueEvents] = proc_get_event2([769 770 771 773 783], NumSamples, events.POS, events.TYP, events.DUR);
CueTrials = CueEvents.TYP;
NumTrials = length(CueTrials);

%% Apply integration for each run
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

%% Comparing simulation with online events
ierror = nan(NumTrials, 1);
tRk = zeros(NumTrials, 1);
tIk = zeros(NumTrials, 1);
for trId = 1:NumTrials
    cstop = CfbEvents.POS(trId) + CfbEvents.DUR(trId)-1;
    crun = Rk(cstop);
    ccue = CueTrials(trId);
    
    cintegrator = integrator{crun};
    ctargets  = [unique(cintegrator.thresholds) 1-unique(cintegrator.thresholds)];
            
    
    if(cintegrator.type == 1)    % ema
        cipp = ema_pp(cstop);
    elseif(cintegrator.type == 2)   % dynamic
        cipp = dyn_pp(cstop);
    end
    
    ierror(trId) = min(abs(cipp-ctargets));
    tRk(trId) = crun;
    tIk(trId) = cintegrator.type;
end



% [~, CfbEvents] = proc_get_event2(781, NumSamples, events.POS, events.TYP, events.DUR);
% [~, CueEvents] = proc_get_event2([771 773 783], NumSamples, events.POS, events.TYP, events.DUR);
% [~, ResEvents] = proc_get_event2([897 898], NumSamples, events.POS, events.TYP, events.DUR);
% NumTrials = length(CfbEvents.TYP);
% 
% 
% %% Computing integrated classification probabilities
% util_bdisp(['[proc] - Computing integrated probabilities for ' num2str(NumRuns) ' runs']);
% ema = 0.5*ones(NumSamples, 1);
% dyn = 0.5*ones(NumSamples, 1);
% for trId = 1:NumTrials
%     cstart = CfbEvents.POS(trId);
%     cstop  = cstart + CfbEvents.DUR(trId);
%     
%     pprob = 0.5;
%     if(Ik(cstart) == 2)
%         coeff = smrinc_integrator_forceprofile(inc(Rk(cstart)), nrpt(Rk(cstart)), bias(Rk(cstart)), degree(Rk(cstart))); 
%     end
%         
%     for sId = cstart+1:cstop
%         if(Ik(cstart) == 1)
%             ema(sId) = smrinc_integrator_ema(rawprobs(sId, 1), pprob, alpha(Rk(cstart)), rejection(Rk(cstart)));
%             pprob = ema(sId);
%         elseif(Ik(cstart) == 2)
%             dyn(sId) = smrinc_integrator_dynamic(rawprobs(sId, 1), pprob, coeff, phi(Rk(cstart)), chi(Rk(cstart)), 0.0625);
%             pprob = dyn(sId);
%         end
%     end
% end