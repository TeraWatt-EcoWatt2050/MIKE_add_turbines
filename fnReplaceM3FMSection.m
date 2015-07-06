function [ retStartLine, retEndLine ] = fnReplaceM3FMSection( filename, section_name, caLines )
%FNREPLACEM3FMSECTION Find and replace a specified section in a .m3fm file.
%   Find and replace a specified section in a MIKE by DHI .m3fm file.
%   Inputs: filename is a char with the path & filename of the .m3fm file.
%           section_name is a char with the name of the section, not
%           including the square brackets. Case-sensitive (should be all caps), e.g. 'TURBINES' for the [TURBINES] section.
%           caLines is a column (nx1) cell array containing the lines that the section should be
%           replaced with. These should not include the opening and closing of the
%           section.
%   Ouputs: retStartLine gives the number of the first line of the new section. If the
%           function failed (most likely because it couldn't find the section) it will
%           be -1.
%           retEndLine gives the number of the last line of the new section.

% Copyright Simon Waldman / Heriot-Watt Universtiy, November 2014.

% read the file into memory as a cell array
FID = fopen(filename, 'r');
if FID == -1
    error('Failed to open file to read');
end
tmp = textscan(FID, '%s', 'Delimiter', '\n'); %this gives us a 1x1 cell with a cell array inside it. The inner one is what we want.
caFile = tmp{1};    % so here's the inner one extracted.
clear tmp;

fclose(FID);

%find the start and end of the section we want.
OrigStartLine = find(strcmp([ '[' section_name ']' ], caFile));    %NB case-sensitive
if isempty(OrigStartLine)    %section wasn't found.
    retStartLine = -1;
    retEndLine = -1;
    return;
elseif length(OrigStartLine) > 1
    error('Multiple sections with desired name');
end

OrigEndLine = find(strcmp([ 'EndSect  // ' section_name ], caFile));
if isempty(OrigEndLine)    %section end wasn't found.
    error('Section end not found');
elseif length(OrigEndLine) > 1
    error('Multiple section ends with desired name');
end

% replace the old with the new section in a new file
caNewFile = [ caFile(1:OrigStartLine); caLines; caFile(OrigEndLine:end) ];

% write the revised file
FID = fopen(filename, 'w');
if FID == -1
    error('Failed to open file to write');
end

fprintf(FID, '%s\n', caNewFile{:});

fclose(FID);

retStartLine = OrigStartLine;
retEndLine = OrigStartLine + length(caLines) + 1;

end

