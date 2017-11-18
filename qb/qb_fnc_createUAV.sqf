/*
    qb_fnc_createUAV
    
    Create an autonomous UAV (B_UAV_02_dynamicLoadout_F) that will circle given position.

    INPUT:
        1 _pos    Position that the UAV will circle
        2 _elev   Elevation for the UAV
        3 _side   Side of the UAV
        
    OUTPUT:
        None

*/

private ["_pos", "_elev", "_side"];
_pos = _this select 0;
_elev = _this select 1;
_side = _this select 2;

if (isServer) then {
    [_pos, _elev, _side] spawn {
        private ["_pos", "_elev", "_side"];
        private ["_uav", "_radius", "_uavPos", "_uavGrp", "_wp"];
        
        _pos = _this select 0;
        _elev = _this select 1;
        _side = _this select 2;
                
        _radius = 600;
        
        if (count _pos == 2) then {
            _pos = _pos + [_elev];
        } else {
            _pos set [2, _elev];
        };

        if (count _pos != 3) exitWith { systemchat "qb_fnc_createUAV: invalid pos / elev"; false };

        _uavGrp = createGroup _side;
        //_uavPos = [(_pos select 0), (_pos select 1) + _radius, (_pos select 2)];
        
        _uav = createVehicle ["B_UAV_02_dynamicLoadout_F", _pos, [], 0, "FLY"];
        _uav setPosATL _pos;
        createVehicleCrew _uav;
        _uavGrp = group ((crew _uav) select 0); // a tad complicated?
        {
            deleteWaypoint _x;
        } forEach (waypoints _uavGrp);
        _wp = _uavGrp addWaypoint [_pos, 0, 0, "uavCenter"];
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointCombatMode "BLUE";
        _wp setWaypointType "LOITER";
        _wp setWaypointLoiterRadius _radius;
        _wp setWaypointLoiterType "CIRCLE";
        _uavGrp setCurrentWaypoint _wp;
        _uav flyInHeight _elev;
    };
};