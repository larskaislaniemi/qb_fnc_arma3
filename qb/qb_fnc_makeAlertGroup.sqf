/*
    qb_fnc_makeAlertGroup
    
    Adds given groups to an "alert group". These groups will come to help to each other in case they become under fire
    or observe an enemy. When a group needs help, all other groups are given a waypoint at their location. After
    some time (see 'qb_cfg_makeAlertGroup_alertTime' below) from most recent alert, they will resume their default action
    (see input '_defaultAction').
    
    Note! 
        1) It is best to use this script for small number of groups. ALL the other groups will come to help one group, if needed.
        2) Forming multiple separate alert groups should work, but this is urrently untested.
        
    INPUT:
        1 _grps                 Array of groups included in the alert group
        2 _enemySide            Enemy side (type: Side)
        3 _defaultAction        Default action (type: Code) to execute on the groups that no longer are helping another group.
                                Typically, recreates (patrol) waypoints for the group. Arguments passed to this routine:
                                [_grps, _argsToDefaultAction]
        4 _argsToDefaultAction  Extra arguments to pass to _defaultAction
        5 _helpDistance         Maximum distance from which to come to help
        
    OUTPUT:
        None
        
    NOTES:
        If a group has variable 'qb_makeAlertGroup_iWillHelp' set to false, it will not help other groups, but will be helped
        if they ask for help.
        
    EXAMPLE:
    
        [[_grp1, _grp2, _grp3], west, {
            private ["_grp", "_pos", "_wp"];
            _grp = _this select 0;
            _posTaor = _this select 1;
            while {(count (waypoints _grp)) > 0} do {
                deleteWaypoint ((waypoints _grp) select 0);
            };
            [[_grp], _posTaor, 250, 6] call qb_fnc_addPatrolWaypoints;
        }, _posTaor] call qb_fnc_makeAlertGroup;
        
*/

if (!isServer) exitWith { false };

qb_cfg_makeAlertGroup_alertTime = 120;
qb_cfg_makeAlertGroup_debug = false;

params ["_grps", "_enemySide", ["_defaultAction", {}], ["_argsToDefaultAction", []], ["_helpDistance", 500]];


{
    _x setVariable ["qb_makeAlertGroup_grps", _grps];
    _x setVariable ["qb_makeAlertGroup_helping", false];
    _x setVariable ["qb_makeAlertGroup_helpingGroup", grpNull];
    // set other defaults, too
    
    [_x, _enemySide, _defaultAction, _argsToDefaultAction, _helpDistance] spawn {
        private ["_grp", "_enemySide", "_defaultAction", "_argsToDefaultAction"];
        private ["_grpFriends", "_helpNeeded", "_helpNeeder", "_wp"];
        _grp = _this select 0;
        _enemySide = _this select 1;
        _defaultAction = _this select 2;
        _argsToDefaultAction = _this select 3;
        _helpDistance = _this select 4;
        
        {
            _x addEventHandler ["Hit", {
                private ["_unit", "_causedBy", "_damage", "_instigator"];
                _unit = _this select 0;
                _causedBy = _this select 1;
                _damage = _this select 2;
                _instigator = _this select 3;
                
                if (qb_cfg_makeAlertGroup_debug) then { systemchat "group is hit"; };
                
                if (not ((group _unit) getVariable ["qb_makeAlertGroup_helping", false])) then {
                    
                    [_unit] spawn {
                        sleep (floor random 15); // he is under fire! not able to call help immediately (maybe...)
                        if (qb_cfg_makeAlertGroup_debug) then { systemchat "asking for help"; };
                        if (alive (_this select 0)) then {
                            (group (_this select 0)) setVariable ["qb_makeAlertGroup_needHelp", true];
                            (group (_this select 0)) setVariable ["qb_makeAlertGroup_needHelpTime", time];
                        };
                    };
                };                
            }];
        } forEach (units _grp);
        
        {
            _x addEventHandler ["Killed", {
                private ["_unit", "_causedBy", "_damage", "_instigator"];
                _unit = _this select 0;
                _killer = _this select 1;
                _instigator = _this select 2;
                
                if (qb_cfg_makeAlertGroup_debug) then { systemchat "someone in group died"; };
                
                if (not ((group _unit) getVariable ["qb_makeAlertGroup_helping", false])) then {
                    
                    [_unit] spawn {
                        sleep (floor random 15); // maybe it takes a while until others spot he is dead...
                        if (qb_cfg_makeAlertGroup_debug) then { systemchat "asking for help"; };
                        if ({alive _x} count (units (group (_this select 0))) > 0) then {
                            (group (_this select 0)) setVariable ["qb_makeAlertGroup_needHelp", true];
                            (group (_this select 0)) setVariable ["qb_makeAlertGroup_needHelpTime", time];
                        };
                    };
                };                
            }];
        } forEach (units _grp);
        
        _grpFriends = _grp getVariable ["qb_makeAlertGroup_grps", []];
        
        while { (!isNull _grp) and (count units _grp > 0) } do {        
            if (_grp getVariable ["qb_makeAlertGroup_helping", false]) then {
                // GROUP IS ALREADY HELPING ANOTHER GROUP
                
                private ["_cancelMission"];
                _cancelMission = false;
                
                // Make sure this group does not call for more help itself
                _grp setVariable ["qb_makeAlertGroup_needHelp", false];
                
                _helpNeeder = _grp getVariable ["qb_makeAlertGroup_helpingGroup", grpNull];
                _timeFromAlert = _helpNeeder getVariable ["qb_makeAlertGroup_needHelpTime", 0];
                if (((isNull _helpNeeder) or (({alive _x} count (units _helpNeeder)) == 0)) and (time - _timeFromAlert > qb_cfg_makeAlertGroup_alertTime)) then { 
                    _cancelMission = true; 
                    if (qb_cfg_makeAlertGroup_debug) then { systemchat "help cancelled (grp is no more)"; };
                } else { 
                    if ((count units _helpNeeder == 0) and (time - _timeFromAlert > qb_cfg_makeAlertGroup_alertTime)) then { 
                        _cancelMission = true; 
                        if (qb_cfg_makeAlertGroup_debug) then { systemchat "help cancelled (no more units)"; };
                    }; 
                    if ((time - _timeFromAlert > qb_cfg_makeAlertGroup_alertTime) and not (_helpNeeder getVariable ["qb_makeAlertGroup_needHelp", false])) then {
                        _cancelMission = true;
                        if (qb_cfg_makeAlertGroup_debug) then { systemchat "help cancelled (no help needed anymore)"; };
                    };
                };
                
                if (_cancelMission) then {
                    _grp setVariable ["qb_makeAlertGroup_helpingGroup", grpNull];
                    _grp setVariable ["qb_makeAlertGroup_helping", false];
                    [_grp, _argsToDefaultAction] call _defaultAction;
                };
            } else {
                // GROUP IS NOT HELPING ANYBODY, CHECK IF HELP NEEDED / IF THIS GROUP NEEDS HELP
                
                if (([_grp, _enemySide] call qb_fnc_knowsAboutSide) > 2) then {
                    // This group needs help
                    if (qb_cfg_makeAlertGroup_debug) then { systemchat "we need help"; };
                    _grp setVariable ["qb_makeAlertGroup_needHelp", true];
                    _grp setVariable ["qb_makeAlertGroup_needHelpTime", time];
                } else {
                    // This group does not need help, what about others?
                    
                    _grp setVariable ["qb_makeAlertGroup_needHelp", false];
                    
                    if (_grp getVariable ["qb_makeAlertGroup_iWillHelp", true]) then {
                        _helpNeeded = false;
                        _helpNeeder = _grp;
                        {
                            if (_x != _grp) then {
                                if (_x getVariable ["qb_makeAlertGroup_needHelp", false]) then {
                                    if (({alive _x} count (units _x)) > 0) then { 
                                        // only help group if it has any members left
                                        // (technical limitation: no members, no location available
                                        if ((leader _grp) distance2d (leader _helpNeeder) < _helpDistance) then {
                                            _helpNeeded = true;
                                            _helpNeeder = _x;
                                        };
                                    };
                                };
                            };
                        } forEach _grpFriends;
                        if (_helpNeeded) then {
                            if (qb_cfg_makeAlertGroup_debug) then { systemchat "found a grp who needs help"; };
                            _grp setVariable ["qb_makeAlertGroup_helping", true];
                            _grp setVariable ["qb_makeAlertGroup_helpingGroup", _helpNeeder];
                             while {(count (waypoints _grp)) > 0} do {
                                deleteWaypoint ((waypoints _grp) select 0);
                             };
                             _wp = _grp addWaypoint [getPos ((units _helpNeeder) select 0), 20];
                             _wp setWaypointType "MOVE";
                             _wp setWaypointBehaviour "AWARE";
                             _wp setWaypointCombatMode "RED";
                             _wp setWaypointSpeed "FULL";
                             _grp setCurrentWaypoint _wp;
                        };
                    };
                };
            };
            sleep 1;
        }; // GROUP IS NO MORE
        if (qb_cfg_makeAlertGroup_debug) then { systemchat "group is gone"; };
    };
} forEach _grps;