/*
    qb_fnc_calcCitySize
    
    Calculate the size of a city, based on the house density. Size is the
    radius of a circle that contains all (most) of the houses of the city.
    "City" can be any group of houses on the map. 

    INPUT:
        1 _pos    Position of the city (use a position roughly in the middle of the city and within
                  50 m from a house.
        
    OUTPUT:
        Radius of a circle that includes all of the houses of the city/town/any group of houses.
        
    City size is determined by counting the number of houses within cocentric circles of increasing radius. If the larger
    circle does not contain 33% (see _cityLimit) more houses than the one smaller circle, the city limit is found. 
    
    Note: Following parameters within the code control how a "city" is defined and how its size is calculated:
        _r1         Minimum size of a city. Also, if _pos is not within _r1 meters from the nearest house, the size of
                    the city will be zero.
        _r2         Maximum size of a city. 
        _step       Radius increase between cocentric circles
        _cityLimit  Default 0.33. The percentage that the number of houses has to increase between cocentric circles for the 
                    city to continue.
           
*/

private ["_pos"];
private ["_r1", "_r2", "_step", "_n", "_nHouses", "_i"];
private ["_rel", "_minVal", "_minLoc", "_citySize"];

_pos = _this select 0;

_qb_fnc_calcCitySize_debug = false;


_r1 = 50;
_r2 = 400;
_step = 40;
_cityLimit = 0.33;


_n = floor ((_r2 - _r1) / _step) + 1;

_nHouses = [];
_rel = [];
   
for "_i" from 0 to _n step 1 do {
    private ["_nearestHouses", "_nNearestHouses"];
    
    _nearestHouses = nearestObjects [_pos, ["house"], _r1 + (_i*_step), true];
    _nNearestHouses = count _nearestHouses;
    
    _nHouses pushBack _nNearestHouses;
};

_rel pushBack (_nHouses select 0);

for "_i" from 1 to _n step 1 do {
    _rel pushBack ((_nHouses select _i) - (_nHouses select (_i-1)));
};

_citySize = 0;
_maxGrowth = 1;

for "_i" from 0 to _n step 1 do {
    scopeName "findLimitLoop";
    
    if (_rel select _i > _maxGrowth) then {
        _maxGrowth = _rel select _i;
    };
    
    _rel set [_i, (_rel select _i) / _maxGrowth];
    
    _citySize = _r1 + _step * _i;
    
    if (_rel select _i < _cityLimit) then {
        breakOut "findLimitLoop";
    };
};

if (_qb_fnc_calcCitySize_debug) then {
    _mrk = createMarker [format ["qb_fnc_size_%1", str (random 10000)], _pos];
    _mrk setMarkerShape "Ellipse";
    _mrk setMarkerSize [_citySize, _citySize];
    _mrk setMarkerBrush "SolidBorder";
    _mrk setMarkerText format ["r: %1", _citySize];
};

_citySize
