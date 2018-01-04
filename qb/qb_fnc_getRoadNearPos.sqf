/*
    qb_fnc_getRoadNearPos
    
    Get a road section near given position

    INPUT:
        1 _pos     Position [location]
        
    OUTPUT:
        Array:
            [ success,  position,  direction ]
        where success is [bool], position is [location] and direction is [number]
        
*/

params ["_pos"];

_searchRadius = 50;
_searchRadiusIncrease = 50;
_maxSearchRadius = 500;

_doStop = false;
_foundRoad = false;

_roadSeg = 0;
_direction = 0;

while { !_foundRoad and !_doStop } do {
    _roadSegs = [_pos select 0, _pos select 1] nearRoads _searchRadius;
    
    if ((count _roadSegs) <= 0) then {
        _foundRoad = false;
        _searchRadius = _searchRadius + _searchRadiusIncrease;
        if (_searchRadius > _maxSearchRadius) then {
            _doStop = true;
        };
    } else {
        _foundRoad = true;
        _roadSeg = _roadSegs select 0;
        _roadConnectedTo = roadsConnectedTo _roadSeg;
        _direction = 0;
        if (count _roadConnectedTo > 0) then {
            _connectedRoad = _roadConnectedTo select 0;
            _direction = [_roadSeg, _connectedRoad] call BIS_fnc_DirTo;
        };
    };
};

_ret = [ false, [0,0,0], 0 ];

if (_foundRoad) then {
    _ret = [
        true,
        getPos _roadSeg,
        _direction
    ];
};

_ret

