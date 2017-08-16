clearvars; clc;

sublist     = {'ah7', 'o8', 'ai2', 'b4', 'e8', 'g6', 'x3'};
nsubjects   = length(sublist);
targetdir   = 'analysis/';

ierror = [];
ippend = [];
Ik_t   = [];
Tk_t   = [];
Ck_t   = [];
Sk_t   = [];

for sId = 1:nsubjects
    csubject = sublist{sId};
    cfilepath = [targetdir csubject '_simulated_integrated.mat'];
    util_bdisp(['[io] - Loading integrated probabilities for subject ' csubject ': ' cfilepath]);
    
    cdata = load(cfilepath);
    cnumsamples = size(cdata.pp, 1);
    
    % Getting events
    cevents = cdata.events;
    % Getting integrated probs
    cema_pp = cdata.ema_pp;
    cdyn_pp = cdata.dyn_pp;
    
    % Getting labels
    cIk = cdata.Ik;
    cTk = cdata.Tk;
    cXk = cdata.Xk;

    % Extracting continuous feedback events
    [~, CfbEvents] = proc_get_event2(781, cnumsamples, cevents.POS, cevents.TYP, cevents.DUR);
    [~, CueEvents] = proc_get_event2([769 770 771 773 783], cnumsamples, cevents.POS, cevents.TYP, cevents.DUR);

    ccuetrials = CueEvents.TYP;
    cnumtrials = length(ccuetrials);
    
    % Comparing simulation with online events
    cierror = nan(cnumtrials, 1);
    cippend = nan(cnumtrials, 1);
    cIk_t = zeros(cnumtrials, 1);
    cTk_t = zeros(cnumtrials, 1);
    for trId = 1:cnumtrials
        cstop = CfbEvents.POS(trId) + CfbEvents.DUR(trId)-1;
        cint = cIk(cstop);
        cth  = cTk(cstop);
        cres = cXk(cstop);
        ccue = ccuetrials(trId);
        
        if (cres == 897)
            ctarget = cth;
        elseif(cres == 898)
            ctarget = 1 - cth;
        end

        if(cint == 1)    % ema
            cipp = [cema_pp(cstop-2) cema_pp(cstop-1) cema_pp(cstop) cema_pp(cstop+1) cema_pp(cstop+2)];
        elseif(cint == 2)   % dynamic
            cipp = [cdyn_pp(cstop-2) cdyn_pp(cstop-1) cdyn_pp(cstop) cdyn_pp(cstop+1) cdyn_pp(cstop+2)];
        end

        [~, csampleid] = min(abs(cipp-ctarget));
        cierror(trId) = cipp(csampleid) - ctarget;
        cippend(trId) = cipp(csampleid);
        cIk_t(trId) = cint;
        cTk_t(trId) = ctarget;
    end
    
    ierror = cat(1, ierror, cierror);
    ippend = cat(1, ippend, cippend);
    Ik_t   = cat(1, Ik_t, cIk_t);
    Tk_t   = cat(1, Tk_t, cTk_t);
    Ck_t   = cat(1, Ck_t, ccuetrials);
    Sk_t   = cat(1, Sk_t, sId*ones(cnumtrials, 1));
end

%% Plots
fig1 = figure;
fig_set_position(fig1, 'All');
NumRows = 3;
NumCols = 3;
colors = get(gca, 'ColorOrder');
for sId = 1:nsubjects
    subplot(NumRows, NumCols, sId); 
    
    hold on;
    for iId = 1:2
        cindex = Ik_t == iId & Sk_t == sId & Ck_t ~= 783;
        plot(ierror(cindex), '.');
        ylim([-0.1 0.5]);
        
        cpos = get(gca, 'Position');
        cpos(2) = cpos(2) - (iId-1)*0.02;
        annotation('textbox', cpos, 'String', ['error_{max}=' num2str(max(abs(ierror(cindex))), '%.3f')], 'LineStyle', 'none', 'FontWeight', 'bold', 'FontSize', 8, 'Color', colors(iId, :));
        grid on;
        xlabel('Trials');
        ylabel('Error');
    end
    hold off;
    
    legend('ema', 'dyn');
    title(sublist{sId});
    
end


