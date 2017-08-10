function [psd, events, labels, settings] = smrinc_concatenate_psd(dir, subject, pattern, extension)

    % Get data
    cpattern = ['*' subject '*' pattern '*'];
    Files = util_getfile(dir, extension, cpattern);
    nfiles = length(Files);
    
    psd = [];
    TYP = [];
    DUR = [];
    POS = [];
    Mk  = [];
    Dk  = [];
    Dn  = [];
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
       Dk  = cat(1, Dk, dateId*ones(size(cdata.psd, 1), 1));
       
       % Concatenate data
       psd = cat(1, psd, cdata.psd);
        
       % Concatenate settings
       settings{fId} = cdata.settings;
    end
    
    events.TYP = TYP;
    events.DUR = DUR;
    events.POS = POS;
    labels.Mk  = Mk;
    labels.Dk  = Dk;
    labels.Dn  = Dn;
end