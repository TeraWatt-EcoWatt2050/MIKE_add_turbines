function [ OutputCA ] = fnGenerateTurbinesSection( GlobalParams, TurbineSpecs, TurbineList )
%FNGENERATETURBINESSECTION Generates the Turbines section for a .m3fm file
%   Accepts three structs: GlobalParams has things that apply to all turbines, 
%   or to the functioning of the script as a whole.
%   TurbineSpecs has parameters that apply to each
%   turbine.
%   TurbineList should contain two 1xn vectors x and y, giving coordinates
%   of turbines.
%   Returns a cell array of lines to be inserted into the model definition
%   file.

% Copyright Simon Waldman / Heriot-Watt Universtiy, November 2014.

%FIXME check inputs.

NumTurbines = length(TurbineList.x);

CA = {}; %initialise cell array

function fnAL(line) %the function adds the given line to CA.
    CA = [ CA; {line} ];
end

% Headers

fnAL('   Touched = 1');
fnAL(['   MzSEPfsListItemCount = ' num2str(NumTurbines)]);
fnAL('   format = 0');
fnAL(['   number_of_turbines = ' num2str(NumTurbines)]);
fnAL(['   output_type = ' num2str(GlobalParams.Output)]);
fnAL(['   output_frequency = ' num2str(GlobalParams.OutputFreq)]);
fnAL(['   output_file_name = ''' GlobalParams.OutputFilename '''']);

% Per-turbine section(s)

for t = 1:NumTurbines
    fnAL('');
    fnAL([ '   [TURBINE_' num2str(t) ']' ]);
    fnAL([ '      Name = ''Turbine ' num2str(t) '''' ]);
    %Will possibly use the turbine name to indicate its type, if/when we allow
    %multiple types.
    fnAL('      include = 1');
    fnAL([ '      coordinate_type = ''' GlobalParams.CoordinateType '''' ]);
    fnAL([ '      x = ' num2str(TurbineList.x(t)) ]);
    fnAL([ '      y = ' num2str(TurbineList.y(t)) ]);
    
    if TurbineSpecs.variabledrag
        fnAL('      description = 2');
    else
        fnAL('      description = 1');
    end
    
    if ~isempty(TurbineSpecs.orientationoverride)
        fnAL([ '      orientation = ' num2str(TurbineSpecs.orientationoverride) ]);
    elseif ~isempty(TurbineList.o)
        fnAL([ '      orientation = ' num2str(TurbineList.o(t)) ]);
    else
        error([ 'No orientation specified for turbine ' num2str(t) '.' ]);
    end  
    
    fnAL([ '      diameter = ' num2str(TurbineSpecs.diameter)]);
    fnAL([ '      centroid = ' num2str(TurbineList.z(t))]);
    fnAL([ '      drag_coefficient = ' num2str(TurbineSpecs.fixeddragcoeff)]);
    
    CA = [ CA; TurbineSpecs.caCtTable ];    %insert table of lift & drag coeffs
    
    fnAL(''); %blank line
    % lots of temporary fixed stuff below, to be changed if I ever allow for
    % correction factors in this script
    fnAL('      [CORRECTION_FACTOR]');
    fnAL('         Touched = 1');
    fnAL('         type = 1'); % don't know what this means
    fnAL('         format = 0'); %for a constant CF. 1 if it varies in time.
    fnAL('         constant_value = 1'); %temporary. Correction factor not implemented yet.
    fnAL('         file_name = ||'); 
    fnAL('         item_name = ''''');
    fnAL('         type_of_soft_start = 2');
    fnAL('         sort_time_interval = 0');
    fnAL('         reference_value = 0');
    fnAL('         type_of_time_interpolation = 1');
    fnAL('      EndSect  // CORRECTION_FACTOR');
    fnAL('');
    fnAL([ '   EndSect  // TURBINE_' num2str(t) ]);
end

fnAL('');
    
OutputCA = CA;

end
