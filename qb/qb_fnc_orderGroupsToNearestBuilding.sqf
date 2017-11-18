/*
    qb_fnc_orderGroupsToNearestBuilding
    
    Order groups to nearest (to them) building.
    NB! Deletes all existing waypoints.

    INPUT:
        1 _grps   Groups
        
    OUTPUT:
        None

        
    #### TODO: Debug, does not (always) work. 
*/

_grps = _this select 0;

{
    private ["_house"];
    
    _house = nearestBuilding (getPos ((units _x) select 0));
    
    while {(count (waypoints _x)) > 0} do {
        deleteWaypoint ((waypoints _x) select 0);
    };
    
    _wp = _x addWaypoint [ getPos _house, 2];
    _wp setWaypointType "MOVE";
    _wp setWaypointBehaviour "AWARE";
    _wp setWaypointSpeed "NORMAL";
    _wp waypointAttachObject _house;
    _x setCurrentWaypoint [_x, 0];
    
} forEach _grps;