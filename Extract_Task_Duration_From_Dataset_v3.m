
%{
    Importing CASAS dataset to create initial loader file for the Neural
    Net. This file should contain

%}

row = 401;
col = 60;
A = zeros(row, col);
projectdir = 'assessmentdata\data';
dinfo = dir(fullfile(projectdir));
dinfo([dinfo.isdir]) = [];     %get rid of all directories including . and ..
% Total number of files in directories
nfiles = length(dinfo);

% Looping through all the files in the directories "nfiles"
for j = 1 : nfiles
    filename = fullfile(projectdir, dinfo(j).name);
    f1 = fopen(filename, 'r');

    str = importdata(filename);
    strCell{1} = str;
    
    COL = 1;
    ROW = j;
 
%%  Calculate duration of each IADL tasks

    for tasks = 1 : 8
        startTask = ~cellfun('isempty',strfind(strCell{1}," "+tasks+"-start"));
        endTask   = ~cellfun('isempty',strfind(strCell{1}," "+tasks+"-end"));
        ST = strCell{1}(startTask);
        ET = strCell{1}(endTask);

        %Find the timestamp of starting a task
        if sum(startTask) ~= 0
            % Only cosidering first occurance of the "x-start" in the ET
            ST = ST{1};
            T1 = strsplit(string(ST),'.');
            T2 = T1{1,1};
            ST = textscan(string(T2),'%s %*[^\n]');
            ST = datetime(string(ST),'Format','HH:mm:ss');
        end
        
        %Find the timestamp of completing the task
        if sum(endTask) ~= 0 
            % Only cosidering first occurance of the "x-end" in the ET
            ET = ET{1};
            T3 = strsplit(string(ET),'.');
            T4 = T3{1,1};
            ET = textscan(string(T4),'%s %*[^\n]');
            ET = datetime(string(ET),'Format','HH:mm:ss');
            %Calculate the duration of the IADL in seconds
            d2s = 24*3600;
            %check if either ST or ET is not null
            if isempty(ST) && isempty(ET)
                seconds = 0;
            elseif isempty(ST)
                seconds = d2s * datenum(ET);
            elseif isempty(ET)
                % set 0 is task is not finished
                seconds = 0;
            else
                seconds = d2s * (datenum(ET) - datenum(ST));
            end    
            A(ROW,tasks) = round(seconds);            
        end
    end
    
%%  Counting sensor firing events  
        for sensors = 1 : 51
            sensor = "M" + num2str(sensors,'%03.f');
            searchStr =  " " + sensor + " " + "ON";
            idx = ~cellfun('isempty',strfind(strCell{1},searchStr));
            % 8 columns already filled with duration of the 8 IADLs
            COL = sensors + tasks;            
            A(ROW,COL) = sum(idx); 
        end

    fclose(f1);
end

%% Writing the imported data file to current folder
csvwrite("CASAS_feature_extraction_.csv", A);

