function [ OutputCA ] = fnGenerateSuppStructsSection( GlobalParams, SupportSpecs, TurbineList )
%%FNGENERATESUPPSTRUCTSSECTION Generates the [PIERS] section for a .m3fm file
%   Accepts three structs: GlobalParams has parameters that apply to all
%   locations or to the function's operation in some other way. 
%   SupportSpecs has parameters that apply to each structure.
%   TurbineList should contain two 1xn vectors x and y, giving coordinates
%   of turbines.
%   Returns a cell array of lines to be inserted into the model definition
%   file.

% Copyright Simon Waldman / Heriot-Watt Universtiy, December 2014.

%FIXME check inputs. Make sure everything that should be there is there,
%and is sane.

NumTurbines = length(TurbineList.x);

CA = {}; %initialise cell array

function fnAL(line) %the function adds the given line to CA.
    CA = [ CA; {line} ];
end

% Headers
fnAL('            Touched = 1');
fnAL([ '            MzSEPfsListItemCount = ' num2str(NumTurbines) ]);
fnAL('            format = 0');
fnAL([ '            number_of_piers = ' num2str(NumTurbines) ]);

% per-pier section

for t = 1:NumTurbines
    fnAL([ '            [PIER_' num2str(t) ']' ]);
    fnAL([ '               Name = ''Pier ' num2str(t) '''' ]);
    fnAL('               include = 1');
    fnAL([ '               coordinate_type = ''' GlobalParams.CoordinateType '''' ]);
    fnAL([ '               x = ' num2str(TurbineList.x(t)) ]);
    fnAL([ '               y = ' num2str(TurbineList.y(t)) ]);
    
    if ~isempty(SupportSpecs.orientationoverride)
        fnAL([ '      orientation = ' num2str(SupportSpecs.orientationoverride) ]);
    elseif ~isempty(TurbineList.o)
        fnAL([ '      orientation = ' num2str(TurbineList.o(t)) ]);
    else
        error([ 'No orientation specified for turbine ' num2str(t) '.' ]);
    end  
    
    fnAL([ '               lamda = ' num2str(SupportSpecs.StreamlineFactor) ]);
    fnAL('               number_of_sections = 1');
    fnAL([ '               type = ' num2str(SupportSpecs.Section) ]);
    if ~isempty(SupportSpecs.dZoverride)
        pierheight = SupportSpecs.dZoverride + SupportSpecs.HeightDelta;
    else
        pierheight = TurbineList.dz(t) + SupportSpecs.HeightDelta;
    end
    fnAL([ '               height = ' num2str(pierheight) ]);
    fnAL([ '               length = ' num2str(SupportSpecs.Length) ]);
    fnAL([ '               width = ' num2str(SupportSpecs.Width) ]);
    fnAL([ '               radious = ' num2str(SupportSpecs.CornerRadius) ]); %this is correct. Somebody at DHI can't spell.
    fnAL([ '            EndSect  // PIER_' num2str(t) ]);
    fnAL('');
end

fnAL('');

OutputCA = CA;


end

