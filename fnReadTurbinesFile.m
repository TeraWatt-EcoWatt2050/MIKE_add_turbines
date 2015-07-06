function [ TurbineInfo ] = fnReadTurbinesFile( filename, skip )
%FNREADTURBINESFILE Reads a CSV file containing turbine information
%   Read it and do some error-checking.
%   Filename is the name of the file as a char.
%   skip is the number of rows to skip at the top of the CSV, eg for headers. 
%   CSV columns should be as follows:
%
%   1. x coordinate
%   2. y coordinate
%   3. z coordinate (hub height, relative to mean sea level. So -30 is 30m
%           below MSL)
%   4. Height above seabed (used for supporting strucutre). If not available,
%           set this column to all zeroes and set an override in the top
%           section of the MIKE_add_turbines.m script.
%   5. (optional): Turbine Orientation.

%   Output: TurbineInfo is a structure containing fields x, y, z and dz, (and optionally o) each of which is
%   a nx1 array where n is the number of turbines.

% Copyright Simon Waldman / Heriot-Watt Universtiy, November 2014.

if (nargin < 1)
    error ('Need a filename');
end
if ~isa(filename, 'char')
    error('First input variable isn''t a char');
end
if ~exist(filename,'file')
    error('File not found');
end
if (nargin < 2)
    skip = 0;
end
%FIXME should probably check that skip is a positive integer?

M = csvread(filename, skip); %Matlab makes an exception to its usual practice and uses 0-based indexing here for "convenience", so it is "rows to skip" rather than "row number to start at".

%FIXME what checking of the input should I be doing here? Successful read? 

switch size(M,2)    % how many columns?
    case 4
        TurbineInfo = struct('x', M(:,1), 'y', M(:,2), 'z', M(:,3), 'dz', M(:,4));
        TurbineInfo.o = [];
    case 5
        TurbineInfo = struct('x', M(:,1), 'y', M(:,2), 'z', M(:,3), 'dz', M(:,4), 'o', M(:,5));
    otherwise
        error('CSV file should have four or five columns: X, Y, Z, dZ, (O).');
end

end

