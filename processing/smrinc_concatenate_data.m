function [psd, events, labels, settings] = smrinc_concatenate_data(dir, subject, pattern, extension)

    % Get data
    cpattern = ['*' subject '*' pattern '*'];
    Files = util_getfile(dir, extension, cpattern);
    nfiles = length(Files);
    
    psd = [];
    TYP = [];
    DUR = [];
    POS = [];
    Mk  = [];
    Rk  = [];
    Dk  = [];
    Dn  = [];
    Ik  = [];
    currdate = '';
    dateId = 0;
    settings = cell(nfiles, 1);
    
    for fId = 1:nfiles
       cdata = load(Files{fId});
       
       % Get modality
       switch(cdata.settings.info.modality)
           case 'offline'
               modalityId = 0;
           case 'online'
               modalityId = 1;
           otherwise
               error('chk:mod', 'Unknown modality');
       end
       
       % Get integrator type
       if (isfield(cdata.settings.log, 'integrator'))
           switch(cdata.settings.log.integrator)
               case 'ema'
                   integratorId = 1;
               case 'dynamic'
                   integratorId = 2;
               otherwise
                   error('chk:mod', 'Unknown modality');
           end
       else
           integratorId = 0;
       end
       
       % Get data
       if(strcmp(cdata.settings.info.date, currdate) == false)
           currdate = cdata.settings.info.date;
           dateId   = dateId + 1;
           Dn = cat(1, Dn, {currdate});
       end
       
       % Concatenate events
       TYP = cat(1, TYP, cdata.events.TYP);
       DUR = cat(1, DUR, cdata.events.DUR);
       POS = cat(1, POS, cdata.events.POS + size(psd, 1));
       Mk  = cat(1, Mk, modalityId*ones(size(cdata.psd, 1), 1));
       Rk  = cat(1, Rk, fId*ones(size(cdata.psd, 1), 1));
       Dk  = cat(1, Dk, dateId*ones(size(cdata.psd, 1), 1));
       Ik  = cat(1, Ik, integratorId*ones(size(cdata.psd, 1), 1));
       
       % Concatenate data
       psd = cat(1, psd, cdata.psd);
        
       % Concatenate settings
       settings{fId} = cdata.settings;
    end
    
    events.TYP = TYP;
    events.DUR = DUR;
    events.POS = POS;
    labels.Mk  = Mk;
    labels.Rk  = Rk;
    labels.Dk  = Dk;
    labels.Dn  = Dn;
    labels.Ik  = Ik;
    labels.Il  = {'none', 'ema', 'dynamic'};
    
end