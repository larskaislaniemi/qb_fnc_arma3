/*
    qb_fnc_addPatrolWaypoints
    
    Add n random waypoints to given groups around given location.
    Groups will move at limited speed with safe behaviour.
    
    INPUT:
        1 _grps    Groups
        2 _pos     Position around which waypoints are created
        3 _radius  Range around _pos for waypoints
        4 _nPoints Number of waypoints to create

    OUTPUT:
        None
                
*/

private ["_grps", "_pos", "_radius", "_nPoints"];

_grps = _this select 0;
_pos = _this select 1;
_radius = _this select 2;
_nPoints = _this select 3;

{
    private ["_grp", "_setPos", "_wp", "_thisNPoints"];
    _grp = _x;
    _thisNPoints = _nPoints;
    
    while { _thisNPoints > 0 } do {
        private ["_dir", "_range", "_wp", "_setPos"];
        _dir = random 360;
        _range = random _radius;
        
        _setPos = [(_pos select 0)+_range*sin(_dir), (_pos select 1)+_range*cos(_dir), (_pos select 2)];
        
        _wp = _grp addWaypoint [ _setPos, 5];
        _wp setWaypointType "MOVE";
        _wp setWaypointBehaviour "SAFE";
        _wp setWaypointSpeed "LIMITED";
        _wp setWaypointCombatMode "WHITE";
            
        _thisNPoints = _thisNPoints - 1;
    };

    _wp = _grp addWaypoint [ _pos, 5]; // TODO: this can be undefined? _pos
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "SAFE";
    _wp setWaypointSpeed "LIMITED";
    _wp setWaypointCombatMode "WHITE";
    
    _wp = _grp addWaypoint [_pos, 5];
    _wp setWaypointType "CYCLE";
    
    _grp setCurrentWaypoint [_grp, 1];
} forEach _grps;