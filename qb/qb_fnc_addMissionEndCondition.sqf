/*
    qb_fnc_addMissionEndCondition
    
    Add condition(s) to end (success or fail) the mission.
    If _logic==0 and ANY of Codes in _conditions return true, then mission will end.
    If _logic==1 and ALL of Codes in _conditions return true, then mission will end.
    
    INPUT:
        1 _conditions   Array of type Code, each returning true/false
        2 _cancellable  Array of type Bool; re-test condition if met once?
        3 _logic        0 = or; 1 = and
        4 _text         Text to show when condition(s) met
        5 _result       Mission result when condition(s) met: 0 = fail; 1 = success
        
    OUTPUT:
        None
        
    NOTES:
        Can be called multiple times to e.g. form conditions for different outcomes.
        
    EXAMPLE:
    
        Mission will end if the intelItem is at base AND an enemy commander is dead. Condition 1 is always re-checked (intelItem
        can be taken out of base before commander is dead); condition 2 is not re-checked (once dead is always dead).
            [
                [
                    { ((missionNamespace getVariable "mission_intelItem") distance (getMarkerPos "mrk_base")) < 20 },
                    { not alive (missionNamespace getVariable "mission_commander") }
                ], 
                [true, false], 1, "All objectives reached!", 1
            ] call qb_fnc_addMissionEndCondition;
        
*/

private ["_conditions", "_cancellable", "_logic", "_text", "_resut"];

qb_cfg_addMissionEndCondition_debug = false;

_conditions = _this select 0; // array of type Code, each returning true/false
_cancellable = _this select 1;// array of type Bool, re-test condition if met once?
_logic = _this select 2;      // 0 = or; 1 = and
_text = _this select 3;       // text to show when condition(s) met
_result = _this select 4;     // mission result when condition(s) met: 0 = fail; 1 = success

[_conditions, _cancellable, _logic, _text, _result] spawn {
    private ["_conditions", "_cancellable", "_logic", "_text", "_result"];

    _conditions = _this select 0; 
    _cancellable = _this select 1;
    _logic = _this select 2; 
    _text = _this select 3; 
    _result = _this select 4; 

    if (qb_cfg_addMissionEndCondition_debug) then { systemchat format ["conditions: %1", count _conditions]; };
    
    _allRet = [];
    for "i" from 0 to ((count _conditions)-1) do {
        _allRet pushBack false;
    };
    
    missionNamespace setVariable ["qb_fnc_addMissionEndcondition_ret", _allRet, true];
    
    while { true } do {
        private ["_ret", "_i", "_finalRet"];
        sleep 5;
        
        _ret = missionNamespace getVariable ["qb_fnc_addMissionEndcondition_ret", []];
        if (qb_cfg_addMissionEndCondition_debug) then { systemchat format ["_ret = %1", _ret]; };
        
        for "_i" from 0 to ((count _conditions)-1) do {
            private ["_code"];
            _code = (_conditions select _i);
            
            if ((_ret select _i) and not (_cancellable select _i)) then {
                // dont change it
            } else {
                _ret set [_i, [] call _code];
                if (qb_cfg_addMissionEndCondition_debug) then { systemchat format ["eval %1: %2", _i, _ret]; };
            };
            
            if (qb_cfg_addMissionEndCondition_debug) then { systemchat format ["condition %1 = %2", _i, _ret select _i]; };
        };
        
        missionNamespace setVariable ["qb_fnc_addMissionEndcondition_ret", _ret, true];
        
        if (_logic == 0) then {
            _finalRet = false;
            for "i" from 0 to ((count _conditions)-1) do {
                _finalRet = _finalRet or (_ret select i);
            };
        } else {
            _finalRet = true;
            for "i" from 0 to ((count _conditions)-1) do {
                _finalRet = _finalRet and (_ret select i);
            };
        };
        
        if (_finalRet) then {
            [ [_text,"BLACK",10] ] remoteExec ["titleText"];
            sleep 10;
            if (_result == 0) then {
                ["LOSER"] remoteExec ["endMission", 0] ;
            } else {
                "EveryoneWon" call BIS_fnc_endMissionServer;
                ["END1"] remoteExec ["endMission", 0] ;
            };
        };
    };
};