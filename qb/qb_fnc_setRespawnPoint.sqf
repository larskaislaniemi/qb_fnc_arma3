/*
    qb_fnc_setRespawnPoint

    Creates a respawn point attach to an unit/object or a group.
    Exists as long as the object is alive or any member of the group is alive.
    
    INPUT:
        1 _unit   Object or group the respawn point will follow
        2 _name   Name shown in respawn menu
        3 _side   Side to which the respawn is available
        
    OUTPUT:
        None
        
*/

private ["_unit", "_name", "_side"];
_unit = _this select 0; 
_name = _this select 1;
_side = _this select 2;


if (isServer) then {
    [_unit, _name, _side] spawn {
        private ["_unit", "_name", "_firstRun", "_marker", "_objAlive", "_pos", "_foundAlive", "_side", "_qb_fnc_setRespawnPoint_debug"];
        _unit = _this select 0; 
        _name = _this select 1;
        _side = _this select 2;

        _qb_fnc_setRespawnPoint_debug = false;

        if (_qb_fnc_setRespawnPoint_debug) then {
            systemchat format ["spawnpoint: %1, %2, %3", _unit, _name, str _side];
        };
        _markerName = ["respawn", str _side, _name] joinString "_";
        _firstRun = 1;
        _objAlive = 1;

        while {!isNil "_unit" AND _objAlive > 0} do {
            if (typeName _unit == "OBJECT") then {
                _pos = getPos _unit;
                if (!(alive _unit)) then {
                    _objAlive = 0;
                };
            } else {
                if (typeName _unit == "GROUP") then {
                    _foundAlive = 0;
                    {
                        if (alive _x) then {
                            _foundAlive = 1;
                            _pos = getPos _x;
                        };
                    } forEach (units _unit);
                    if (_foundAlive == 0) then {
                        _objAlive = 0;
                    };
                };
            };

            if (_firstRun > 0 AND _objAlive > 0) then {
                _firstRun = 0;
                _marker = createMarker [_markerName, _pos];
                _marker setMarkerText _name;
            };

            if (_objAlive > 0) then { _marker setMarkerPos (_pos); };
            sleep 5;
        };

        if (_firstRun < 1) then {
            deleteMarker _marker;
        };
    };
};