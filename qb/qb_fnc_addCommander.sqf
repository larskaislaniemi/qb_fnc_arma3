/*
    qb_fnc_addCommander
    
    Subroutine to create a virtual commander which defends a given city.
    
    1) Creates groups of units within a given city 
        a) Number of groups depends on city size
        b) Composition of groups is defined by 'qb_cfg_addCommander_groupBool'
    2) Virtual commander coordinates waypoints for the groups, taking into account
       the presence of enemies and the alert status of groups.

    INPUT:
        1 _mrk           Marker that defines the city (place next to / at a house in the middle of a city/village.
        2 _enemyDensity  Num of enemy groups per 10 000 m^2
        3 _side          Side of groups
        
    OUTPUT:
        none
       
    ### TODO: coordination of waypoints and helping functions unfinished
    
*/

if (!isServer) exitWith { false };

params [
    ["_mrk", ""], 
    ["_enemyDensity", 0.3], 
    ["_side", east]
];
private ["_firstRun"];


qb_cfg_addCommander_alertHalftime = 15;        // how quickly alerts about enemies fade to half
qb_cfg_addCommander_radioCheckinTime = 5;      // how often groups are polled about near by enemies
qb_cfg_addCommander_radioCommandInterval = 5;  // how often commander gives command to groups
qb_cfg_addCommander_innerSectorSize = 0.3;     // (relative) size of the central sector
qb_cfg_addCommander_costOfGroupHit = 1e6; 
qb_cfg_addCommander_alertCoefPerStep = exp ((ln 0.5) / (qb_cfg_addCommander_alertHalftime / qb_cfg_addCommander_radioCheckinTime));

qb_cfg_addCommander_groupBool = [
    ["O_G_Soldier_F", "O_G_Soldier_F", "O_G_Soldier_F"]
];

qb_cfg_addCommander_debug = true;


qb_fnc_calculateSector = {
    params [
        ["_pos", [0,0,0]],
        ["_center", [0,0,0]],
        ["_innerSectorSize", 0]
    ];
    
    private ["_dx", "_dy", "_dist", "_angle", "_sector"];
    
    _dx = (_pos select 0) - (_center select 0);
    _dy = (_pos select 1) - (_center select 1);
    _dist = _pos distance _center;
    _angle = _dx atan2 _dy;
    if (_dist < _innerSectorSize) then {
        _sector = 0;
    } else {
        _sector = floor ((_angle+180) / 30) + 1;
    };
    
    _sector
};

_firstRun = 1;

if (not isNil "qb_sta_addCommander_init") then {
    if (qb_sta_addCommander_init > 0) then {
        _firstRun = 0;
    } else {
        /* this shouldnt happen really */
        _firstRun = 0;
    };
} else {
    qb_sta_addCommander_init = 0;
    _firstRun = 1;
};

if (_firstRun > 0) then {
    private ["_citySize", "_cityArea", "_nGroupsEnemy", "_i", "_cityPos"];
    
    _cityPos = getMarkerPos _mrk;
    _citySize = [_cityPos] call qb_fnc_calcCitySize;
    _cityArea = 3.14 * _citySize * _citySize;
    _nGroupsEnemy = floor (_enemyDensity * (_cityArea / 10000.0)) + 1;

    qb_cfg_addCommander_cityPos = _cityPos;
    qb_cfg_addCommander_citySize = _citySize;
    
    
    
    /* CREATE GROUPS */
    
    qb_sta_addCommander_groups = [];

    _i = 0;
    while { _i < _nGroupsEnemy } do {
        private ["_igrp", "_pos", "_grp", "_obj"];
        _pos = [_mrk, _citySize] call qb_fnc_getPosNearMarker;
        _grp = createGroup _side;
        _igrp = qb_cfg_addCommander_groupBool call BIS_fnc_selectRandom;
        {
            _obj = _grp createUnit [_x, _pos, [], 0, "NONE"];
        } forEach _igrp;
        
        _grp setVariable ["qb_sta_addCommander_status", "patrol"];
        _grp setVariable ["qb_sta_addCommander_underFire", 0];
        
        {
            _x addEventHandler ["Hit", {
                [_this select 0] spawn {
                    systemchat "Unit was hit";
                    _val = (group (_this select 0)) getVariable ["qb_sta_addCommander_underFire", 0];
                    (group (_this select 0)) setVariable ["qb_sta_addCommander_underFire", _val + 1];
                    sleep 60;
                    _val = (group (_this select 0)) getVariable ["qb_sta_addCommander_underFire", 0];
                    (group (_this select 0)) setVariable ["qb_sta_addCommander_underFire", _val - 1];
                };
            }];
        } forEach units _grp;
        
        qb_sta_addCommander_groups pushBack _grp;
        _i = _i + 1;
    };    
    
    qb_sta_addCommander_nGroupsAlive = _nGroupsEnemy;
    if (qb_cfg_addCommander_debug) then { systemchat format ["Added %1 enemy groups", _nGroupsEnemy]; };
    
    
    /* CREATE DEFAULT ACTIONS FOR GROUPS */

    {
        _x setVariable ["qb_cfg_addCommander_defaultAction", {
            _grp = _this select 0;
            while {(count (waypoints _grp)) > 0} do { deleteWaypoint ((waypoints _grp) select 0); };
            [[_grp], qb_cfg_addCommander_cityPos, qb_cfg_addCommander_citySize * 2.0, 6] call qb_fnc_addPatrolWaypoints
        }];
    } forEach qb_sta_addCommander_groups;
    
    
    /* CALL DEFAULT ACTION ON ALL */
    
    {
        _code = _x getVariable ["qb_cfg_addCommander_defaultAction", {}];
        [_x] spawn _code;
    } forEach qb_sta_addCommander_groups;
    
    
    qb_sta_addCommander_init = 1;


    
    /* CHECK ALIVE STATUS OF GROUPS */
    
    [] spawn {
        waitUntil { qb_sta_addCommander_init > 0 };
        while { true } do {
            private ["_groups_new"];
            _groups_new = +qb_sta_addCommander_groups;
            {
                if (isNull _x) then {
                    _groups_new = _groups_new - [_x];
                };
                if ({ alive _x } count units _x == 0) then {
                    _groups_new = _groups_new - [_x];
                };
            } forEach qb_sta_addCommander_groups;
            qb_sta_addCommander_groups = _groups_new;

            qb_sta_addCommander_nGroupsAlive = count qb_sta_addCommander_groups;
            
            /* TODO: qb_sta_addCommander_nGroupsAlive should not be _immediately_
               available to commander (but we need this variable to avoid
               references to null objects...)
            */
            
            sleep 2;
        };
    };
    
    
    /* ENEMY REPORT LOOP */
    
    [] spawn {
        waitUntil { qb_sta_addCommander_init > 0 };
        
        while { true } do {
            
            /* POLL GROUPS ABOUT NEARBY ENEMIES */
            
            qb_sta_addCommander_sectorOwnUnitcount = [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1]; // 0->1 to avoid div by zero later
            qb_sta_addCommander_sectorEnemies = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]; 

            {
                /* reset almost zero sector costs to zero */
                qb_sta_addCommander_sectorEnemies set [_forEachIndex, qb_cfg_addCommander_alertCoefPerStep * _x];
                if (_x < 10) then { qb_sta_addCommander_sectorEnemies set [_forEachIndex, 0.0]; };
            } forEach qb_sta_addCommander_sectorEnemies;
            
            /* poll each group */
            {
                {
                    private ["_targets", "_unit"];
                    _unit = _x;
                    if (alive _unit) then {
                        private ["_pos", "_dx", "_dy", "_dist", "_angle", "_sector", "_sectorCost"];
                        
                        /* Calculate targets in each sector */
                        _targets = _unit nearTargets 500;
                        {
                            // _x is [pos, type, side, subj cost, obj, posaccu]
                            _pos = _x select 0;
                            _cost = _x select 3;
                            if (_cost > 1) then {
                                _sector = [_pos, qb_cfg_addCommander_cityPos, qb_cfg_addCommander_innerSectorSize * qb_cfg_addCommander_citySize] call qb_fnc_calculateSector;
                                _sectorCost = (qb_sta_addCommander_sectorEnemies select _sector) + _cost;
                                qb_sta_addCommander_sectorEnemies set [_sector, _sectorCost];
                            };
                        } forEach _targets;

                        /* Calculate own units in each sector */
                        _pos = getPos _unit;
                        _sector = [_pos, qb_cfg_addCommander_cityPos, qb_cfg_addCommander_innerSectorSize * qb_cfg_addCommander_citySize] call qb_fnc_calculateSector;
                        qb_sta_addCommander_sectorOwnUnitcount set [_sector, (qb_sta_addCommander_sectorOwnUnitcount select _sector) + 1];
                    };
                } forEach (units _x);
            } forEach qb_sta_addCommander_groups;
            
            {
                private ["_pos", "_dx", "_dy", "_dist", "_angle", "_sector", "_sectorCost"];
                if ((_x getVariable ["qb_sta_addCommander_underFire", 0]) > 0) then {
                    _sector = [getPos (leader _x), qb_cfg_addCommander_cityPos, qb_cfg_addCommander_innerSectorSize * qb_cfg_addCommander_citySize] call qb_fnc_calculateSector;
                    _sectorCost = (qb_sta_addCommander_sectorEnemies select _sector) + qb_cfg_addCommander_costOfGroupHit;
                    qb_sta_addCommander_sectorEnemies set [_sector, _sectorCost];
                };
            } forEach qb_sta_addCommander_groups;
            
            if (qb_cfg_addCommander_debug) then { systemchat format ["Sector cost: %1", qb_sta_addCommander_sectorEnemies]; }; 
            qb_sta_addCommander_groupPollDone = true;
            sleep qb_cfg_addCommander_radioCheckinTime;
        };
    };
    
    
    /* CONTROL LOOP */
    
    [] spawn {
        private ["_i", "_max", "_n", "_sortedSectors", "_sectorsNeedHelp", "_tempEnemies"];
        
        waitUntil { !isNil "qb_sta_addCommander_groupPollDone" };
        waitUntil { qb_sta_addCommander_groupPollDone };
        
        while { true } do {
            
            /* FIND SECTORS WHERE ENEMIES ARE KNOWN TO EXIST */
            
            _tempEnemies = +qb_sta_addCommander_sectorEnemies;
            qb_sta_addCommander_sectorFocus = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
            
            
            /* finds the local maxima; includes scaling by number of observers */
            for "_i" from 1 to 11 do {
                _tempEnemies set [_i, (qb_sta_addCommander_sectorEnemies select _i) /
                    ((qb_sta_addCommander_sectorOwnUnitcount select (_i-1)) +
                    (qb_sta_addCommander_sectorOwnUnitcount select _i) +
                    (qb_sta_addCommander_sectorOwnUnitcount select (_i+1)))];
            };
            _tempEnemies set [12, (qb_sta_addCommander_sectorEnemies select 12) /
                ((qb_sta_addCommander_sectorOwnUnitcount select 11) +
                (qb_sta_addCommander_sectorOwnUnitcount select 12) +
                (qb_sta_addCommander_sectorOwnUnitcount select 1))];
            _tempEnemies set [1, (qb_sta_addCommander_sectorEnemies select 1) /
                ((qb_sta_addCommander_sectorOwnUnitcount select 2) +
                (qb_sta_addCommander_sectorOwnUnitcount select 12) +
                (qb_sta_addCommander_sectorOwnUnitcount select 1))];
            for "_i" from 1 to 11 do {
                if ((_tempEnemies select _i) > (_tempEnemies select (_i-1)) AND
                    (_tempEnemies select _i) > (_tempEnemies select (_i+1))) then {
                    qb_sta_addCommander_sectorFocus set [_i, (_tempEnemies select _i) + 
                        (_tempEnemies select (_i-1)) +
                        (_tempEnemies select (_i+1)) + (random 10)]; // random to make the value unique
                };
            };
            if ((_tempEnemies select 1) > (_tempEnemies select 12) AND
                (_tempEnemies select 1) > (_tempEnemies select 2)) then {
                qb_sta_addCommander_sectorFocus set [1, (_tempEnemies select 10) + 
                    (_tempEnemies select 2) +
                    (_tempEnemies select 12) + (random 1)];
            };
            if ((_tempEnemies select 12) > (_tempEnemies select 11) AND
                (_tempEnemies select 12) > (_tempEnemies select 1)) then {
                qb_sta_addCommander_sectorFocus set [12, _tempEnemies select 12 + 
                    (_tempEnemies select 1) +
                    (_tempEnemies select 11) + (random 10)];
            };
            qb_sta_addCommander_sectorFocus set [0, (_tempEnemies select 0) / (qb_sta_addCommander_sectorOwnUnitcount select 0)];  

            /* count how many sectors need help */
            _max = selectMax qb_sta_addCommander_sectorFocus;
            if (_max <= 0) then {
                _n = 0;
            } else {
                _n = 0;
                for "_i" from 0 to 12 do {
                    if ((qb_sta_addCommander_sectorFocus select _i) > 0) then {
                        _n = _n + 1;
                    }
                };
            };
            
            /* put them in order and act */
            if (_n == 0) then {
                // all is quiet
                systemchat "all is quiet";
                {
                    if (_x getVariable ["qb_sta_addCommander_status", ""] != "patrol") then {
                        _x setVariable ["qb_sta_addCommander_status", "patrol"];
                        _code = _x getVariable ["qb_cfg_addCommander_defaultAction", {}];
                        [_x] spawn _code;
                    };
                } forEach qb_sta_addCommander_groups;
            } else {
                // panic!
                _sortedSectors = +qb_sta_addCommander_sectorFocus;
                _sortedSectors sort false;
                _sectorsNeedHelp = [];
                
                for "_i" from 0 to (_n-1) do {
                    _sectorsNeedHelp pushBack (qb_sta_addCommander_sectorFocus find (_sortedSectors select _i));
                };
            
                if (qb_cfg_addCommander_debug) then { systemchat format ["sectors need help: %1 (%2: %3)", _sectorsNeedHelp, _n, _sortedSectors]; };
            };
            
            sleep qb_cfg_addCommander_radioCommandInterval;
            
        }
    };
    
    
} else {
    /* NOT YET IMPLEMENTED */
};

