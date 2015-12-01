% Script to take an input file of turbine locations and add them all as
% turbines into an existing MIKE .m3fm file. Also works for .mfm files from
% coupled MIKE21/3 models.

% Copyright Simon Waldman / Heriot-Watt Universtiy, November 2014.

%% Variables

m3fmFilename = 'D:\MIKE Zero Projects\New_TW_Model\PFOW_Coupled_V02.mfm';    %filename of model definition file
TurbineListFilename = 'D:\Datasets\TeraWatt data\Array layouts\150331\depth calcs\all_UTM30N_withorientations.csv';    % filename of CSV with turbine info. See fnReadTurbinesFile.m for details of this file.
TurbineListSkip = 1; % number of lines of header to skip at the start of the turbine list

% Global setup parameters
% This struct contains parameters that apply globally; TurbineSpecs
% contains things that could vary between turbine types.

GlobalParams.Output = 1; %0 or 1 - do we want an output file with force at turbine, etc
GlobalParams.OutputFreq = 1; % output every n timesteps
GlobalParams.OutputFilename = 'turbine_data.dfs0';   % filename. Don't specify a path, do that at runtime with other result files.
% string that MIKE uses to describe a coordinate system. Needs to match that used for the coordinates in the CSV. This is long & complicated. Best to define a sample turbine, open up the .m3fm file, then copy-paste into here.
GlobalParams.CoordinateType = 'PROJCS["UTM-30",GEOGCS["Unused",DATUM["UTM Projections",SPHEROID["WGS 1984",6378137,298.257223563]],PRIMEM["Greenwich",0],UNIT["Degree",0.0174532925199433]],PROJECTION["Transverse_Mercator"],PARAMETER["False_Easting",500000],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-3],PARAMETER["Scale_Factor",0.9996],PARAMETER["Latitude_Of_Origin",0],UNIT["Meter",1]]';

% Turbine specs
% FIXME these should be read from an input file eventually. At present we
% only support one type of turbine, but future enhancement may allow
% multiple types.
% TurbineSpecs is stuff that applies to each turbine.

TurbineSpecs.diameter = 20;     %metres

TurbineSpecs.variabledrag = true;  % set TRUE to use the Cd/Cl table, or FALSE for a fixed omnidirectional drag coeff.

TurbineSpecs.fixeddragcoeff = 0.9;   % must exist, but only used if variabledrag=FALSE

TurbineSpecs.caCtTable = {'[TABLE]';    %Table of lift & drag coefficients. Must exist, but ignored unless variabledrag=true.
        'number_of_directions = 5'; 
        'minimum_direction = 0';
        'maximum_direction = 360';
        'number_of_speeds = 15';
        'minimum_speed = 0.75';
        'maximum_speed = 4.25'; %4.25 for Terawatt profile
        %Terawatt profile below
        'cd_1 = 0.0, 0.0, 0.0, 0.0, 0.0';  % drag coefficients for first speed at all directions
        'cd_2 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_3 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_4 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_5 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_6 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_7 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_8 = 0.85, 0.0, 0.85, 0.0, 0.85';
        'cd_9 = 0.635, 0.0, 0.635, 0.0, 0.635';
        'cd_10 = 0.490, 0.0, 0.490, 0.0, 0.490';
        'cd_11 = 0.385, 0.0, 0.385, 0.0, 0.385';
        'cd_12 = 0.308, 0.0, 0.308, 0.0, 0.308';
        'cd_13 = 0.250, 0.0, 0.250, 0.0, 0.250';
        'cd_14 = 0.205, 0.0, 0.205, 0.0, 0.205';
        'cd_15 = 0.0, 0.0, 0.0, 0.0, 0.0';

        'cl_1 = 0, 0, 0, 0, 0';  %lift coefficients for first speed at all directions
        'cl_2 = 0, 0, 0, 0, 0';
        'cl_3 = 0, 0, 0, 0, 0';
        'cl_4 = 0, 0, 0, 0, 0';
        'cl_5 = 0, 0, 0, 0, 0';
        'cl_6 = 0, 0, 0, 0, 0';
        'cl_7 = 0, 0, 0, 0, 0';
        'cl_8 = 0, 0, 0, 0, 0';
        'cl_9 = 0, 0, 0, 0, 0';
        'cl_10 = 0, 0, 0, 0, 0';
        'cl_11 = 0, 0, 0, 0, 0';
        'cl_12 = 0, 0, 0, 0, 0';
        'cl_13 = 0, 0, 0, 0, 0';
        'cl_14 = 0, 0, 0, 0, 0';
        'cl_15 = 0, 0, 0, 0, 0';
        'EndSect  // TABLE'};
    % note re drag & lift coefficients - easiest way to think about this
    % table structure is that the way it's laid out above is the same as
    % the shape of the table in the GUI - rows are speeds, columns are
    % directions.
    
TurbineSpecs.orientationoverride = [];    % Leave blank ([]) to use directions given for individual turbines in TurbineList.
                                        %   Enter here to force all
                                        %   turbines to one orientation -
                                        %   most useful if they have equal
                                        %   performance from every
                                        %   direction (i.e. they
                                        %   weathervane).
                                        
% Supporting structure specs.
SupportSpecs.IncludeSupportingStructs = true;  % choose whether supporting structures will be included.

% We approximate supporting structures using MIKE's built in "Pier"
% structure type, which is intended for bridge structures.

% Pier type:
SupportSpecs.Section = 0;   % 0 = circular, 1 = rectangular, 2 = elliptical
SupportSpecs.StreamlineFactor = 1.02; %default = 1.02. See MIKE documentation re this value.
SupportSpecs.Width = 2.5;   % metres. For circular, this is diameter.
SupportSpecs.Length = 0;    % metres. Not used for circular.
% Orientation will be set to the same as the turbine. (obviously doesn't
% matter for circular structures). 
% haven't tested (have only used circular so far), but assume that this means that Width = across flow, length = along flow
SupportSpecs.CornerRadius = 0;  %metres. Only for rectangular section.
SupportSpecs.HeightDelta = 0;   %metres. Difference in elevation of top of pier compared to turbine hub height.
    % i.e. pier will extend from seabed to (turbine centre + this).

SupportSpecs.orientationoverride = TurbineSpecs.orientationoverride;    %don't change.

SupportSpecs.dZoverride = []; % This is the height of the turbine above the seabed, and is used
                                % for the supporting structure. Leave blank
                                % ([]) to use column 4 of the CSV to
                                % provide this. Enter it here to force it
                                % for all turbines (and then column 4 of
                                % the CSV will be ignored). Note that this
                                % is *not* the same as the turbine hub
                                % height, because that is specified
                                % relative to mean sea level, and this is
                                % relative to the seabed. This script
                                % doesn't know the bathymetry, so it can't
                                % convert one to the other.

%% Read in the turbine locations

TurbineList = fnReadTurbinesFile(TurbineListFilename, TurbineListSkip);
%TurbineList is a struct with x, y and z arrays inside it. (z is centroid elevation). 

%% Generate the lines to go into the output file

TurbinesSectionCA = fnGenerateTurbinesSection(GlobalParams, TurbineSpecs, TurbineList); %returns a cell array of the lines to insert for the TURBINES section.

if SupportSpecs.IncludeSupportingStructs
    SupportsSectionCA = fnGenerateSuppStructsSection(GlobalParams, SupportSpecs, TurbineList); %ditto, for the "PIERS" section.
end

%% Replace the appropriate sections in the m3fm file with the ones we generated.

[ StartLine, EndLine ] = fnReplaceM3FMSection(m3fmFilename, 'TURBINES', TurbinesSectionCA);
if StartLine == -1
    error('Something went wrong with replacing the Turbines section in the file. Possibly there wasn''t an existing TURBINES section?');
else
    sprintf('New [TURBINES] section inserted between lines %i and %i in %s.\n', StartLine, EndLine, m3fmFilename)
end

if SupportSpecs.IncludeSupportingStructs
    [ StartLine, EndLine ] = fnReplaceM3FMSection(m3fmFilename, 'PIERS', SupportsSectionCA);
    if StartLine == -1
        error('Something went wrong with replacing the supports section in the file. Possibly there wasn''t an existing PIERS section?');
    else
        sprintf('New [PIERS] section inserted between lines %i and %i in %s.\n', StartLine, EndLine, m3fmFilename)
    end
end