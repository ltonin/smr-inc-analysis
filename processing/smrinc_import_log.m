function info = smrinc_import_log(gdfname, logname)
    info = [];
    [dirpath, filename, extension] = fileparts(gdfname);
    
    if nargin == 1
        cinfo = util_getfile_info(gdfname);
        logname = [dirpath cinfo.subject '.' cinfo.date '.log'];
    end

    pattern = [filename extension];
    
    line = get_log_line(logname, pattern);
    
    if (line == -1)
        warning(['Cannot find logfile: ' logname]);
        return;
    elseif isempty(line)
        warning(['Cannot find entry for ' pattern ' in ' logname]);
        return;
    end
 
    info = get_log_field(line);    
    
end

function line = get_log_line(logname, pattern)
    line = [];
    fid = fopen(logname);
    if(fid == -1)
        line = -1;
        return;
    end
    
    tline = fgets(fid);
    while ischar(tline)
        if ~isempty(strfind(tline, pattern))
            line = tline;
            break;
        end
        tline = fgets(fid);
    end
    fclose(fid);
end

function result = get_log_field(strline)

    result = [];
    fields = regexp(strline, '(?<name>\w*)=(?<value>(([+-]?([0-9]+([.][0-9]*)?|[.][0-9]+))|(\w*[\.]\w*)|(\w*)))', 'names');
    nfields = length(fields);
    
    for i = 1:nfields
        cname  = fields(i).name;
        cvalue = fields(i).value;
        result.(cname) = cvalue;
    end
    
 
end

