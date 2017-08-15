function ind = smrinc_feature2index(bands, freqs, chans)

    nfreqs = length(freqs);
    nchans = length(chans);
    
    if(length(bands) ~= nchans)
        error('chk:format', 'Wrong format for eegc3 input bands. Number of channels different from the lenght of bands');
    end
    
    ind = [];
    for chId = 1:nchans
       
        cbands = bands{chId};
        cchan  = chans(chId);
        
        if(isempty(cbands))
            continue;
        end
        
        [~, freqId] = intersect(freqs, cbands);
        
        if(isempty(freqId) == true)
            error('chk:frq', 'No match found in the frequency vector');
        end
        
        chanId  = repmat(cchan, [length(cbands) 1]);
        
        ind = cat(1, ind, sub2ind([nfreqs nchans], freqId, chanId)); 
        
    end
    
end