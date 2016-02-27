% Script to take a 2-column CSV with just X,Y coordinates,
% and a MIKE .mesh file, and produce the input file required for 
% MIKE_add_turbines. It will only work for triangular meshes, because I
% haven't bothered to allow for >3 nodes per element.
% Requires mapping toolbox, and the DHI toolbox.
% In the long run, should really merge this into the main script.

% Copyright Simon Waldman / Heriot-Watt University 2016

% The latest version of this script may be found at
% https://github.com/TeraWatt-EcoWatt2050/MIKE_add_turbines.
% If it helps you with a publication or report, an acknowledgement would be
% appreciated.

%% Variables

InputCSVFilename = 'C:\documents\Projects\TeraWatt\Array layouts\layout_brough_ness_UTM30N.txt'; % CSV file with 2 columns, x and y coords.
SkipLines = 1; %lines to skip at the start of the input file, eg for header info.
MeshFilename = 'C:\documents\MIKE Zero Projects\new_TW_model\PFOW_Mesh_V02.mesh'; %MIKE .mesh file
OutputCSVFilename = 'C:\temp\testoutput.csv'; % filename for output file

ConvertLLtoUTM = 0; % if the original CSV is in lon/lat, and the model is in UTM, 
                    % set this to 1 to convert automatically.
                    %    In any other situation set this to 0, and the
                    %    coordinates will be left alone - they will need to
                    %    match the form used in the MIKE model.
                    
HeightOffSeabed = 15; % desired distance from seabed to turbine hubs in metres
                      % This has to be the same for all turbines. If you
                      % want to be cleverer than this, with different heights
                      % for different turbines, you probably want to
                      % create the CSV file yourself by other means and not
                      % use this script.
TidalAmplitude = 4; % how far does water level drop below zero?
TurbineDiameter = 20; % if this is non-zero, then turbines that would break the surface (given TidalAmplitude because of shallow bathymetry) will be lowered to just stay submerged.


%% Read intput files

Input = csvread( InputCSVFilename, SkipLines );
%FIXME check for a successful read, that X and Y are the same length, etc.

NumTurbs = size(Input,1);

[et, nodes] = mzReadMesh(MeshFilename);  %et = element table; nodes = nodes.
trMesh2D = triangulation(et(:,1:3), nodes(:,1:2)); %this is a 2D version of the mesh, using only the horizontal node positions. This makes things simpler than if it has elevation data.

%% Convert coordinates if requested

if ConvertLLtoUTM
    myutmzone = utmzone( Input(2,:), Input(1,:) );
    [ellipsoid,estr] = utmgeoid(myutmzone);
    utmstruct = defaultm('utm'); 
    utmstruct.zone = myutmzone; 
    utmstruct.geoid = ellipsoid; 
    utmstruct = defaultm(utmstruct);

    [ X, Y ] = mfwdtran(utmstruct, Input(2,:), Input(1,:));   %Y then X - it's lat then lon.    
else
    X = Input(:,1);
    Y = Input(:,2);
end


%% Get seabed elevations for the relevant elements.

% find element numbers corresponding to the turbine locations
ElNo = pointLocation(trMesh2D, X, Y);

% now find the seabed elevation at each, by taking the mean of the node
% elevations pertaining to that element. NB this is correct, rather than
% interpolating from nodes and predicting a z-value at the exact turbine
% coordinates, because MIKE appears to use a single depth throughout a 
% horizontal element, equal to that mean value (i.e. piecewise constant
% depth).
TurbineNodes = et(ElNo,:); %this is a NumTurbs x 3 matrix of the node numbers pertaining to each turbine
NodeElevations = nan(size(TurbineNodes)); 
for t = 1:NumTurbs
    NodeElevations(t,:) = nodes( TurbineNodes(t,:), 3 );
end
% we should now have a NumTurbs x 3 matrix of node elevations
ElementElevations = squeeze( mean( NodeElevations, 2 ) ); %and now a vector of mean elevations for elements.

%% Work out turbine elevations

% first pass at elevations is simply the desired distance above the seabed
TurbineElevations = ElementElevations + HeightOffSeabed;

% do any break the surface? If so, sink them to stay (just) submerged &
% note how many.
LowestSurface = -1 * ( TidalAmplitude + TurbineDiameter/2 );
NumLowered = length(find( TurbineElevations > LowestSurface ));
TurbineElevations( TurbineElevations > LowestSurface ) = LowestSurface;

if NumLowered > 0
    fprintf('%i turbines were lowered to prevent them breaking the surface.\n', NumLowered);
end

% now do any scrape the seabed? If so, stop and complain.

BottomScrapers = find( TurbineElevations < ElementElevations );
if ~isempty(BottomScrapers)
    fprintf('Error: After being lowered to avoid breaking the surface, the following\n');
    fprintf('       turbine numbers scrape the seabed:\n\n');
    fprintf('%i ', BottomScrapers);
    fprintf('\n\nAborting.\n');
    error('Turbines scraping bottom');
end

% now calculate the distances from seabed to hub (which may not equal the
% original HeightOffSeabed if turbines were lowered above)
FinalHeightsAboveSeabed = TurbineElevations - ElementElevations;
    
%% Generate the output file

% form the required values into a matrix
Output = [ X Y TurbineElevations FinalHeightsAboveSeabed ];

% write it out
csvwrite( OutputCSVFilename, Output );