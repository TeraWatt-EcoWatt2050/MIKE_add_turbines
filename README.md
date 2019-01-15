# MIKE_add_turbines
MATLAB script for adding tidal turbines to MIKE by DHI models.

This script takes a CSV file of turbine locations and adds them to a MIKE
model. It can cope with large numbers of turbines (tested with 1000), and thus
can save a lot of clicking.

The supplementary script Prep_CSV_File.m can take just X and Y coordinates and a MIKE .mesh file and produce the input file required for the main script.

Testing has been done with MIKE 2012. Later versions may work - at least until there are substantial changes to the turbine functionality - but no promises. If you use it with a later version, please let me know what happens!

If you use it in a project that leads to a report or publication I would 
appreciate credit and, if appropriate, a citation for the following paper
for which it was developed:

Waldman S, Baston S, Nemalidinne R, Chatzirodou A, Venugopal V, Side J, “Implementation of tidal turbines in MIKE 3 and Delft3D models of Pentland Firth & Orkney Waters” (2017)
Ocean & Coastal Management. http://dx.doi.org/10.1016/j.ocecoaman.2017.04.015

Improvements to this script are welcome. The latest version may be found at https://github.com/TeraWatt-EcoWatt2050/MIKE_add_turbines.

-Simon Waldman.

Address for correspondance or queries: simon@simonwaldman.me.uk
