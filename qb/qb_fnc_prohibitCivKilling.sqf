/*
    qb_fnc_prohibitCivKilling
    
    Prohibits killing members of given faction (and/or unarmed units). Mission will fail if too many prohibited kills take place.
        
    INPUT:
        1 _faction          Faction of units that should not be killed
        2 _prohibitUnarmed  Prohibit _also_ killing of unarmed units? true/false
        3 _maxCount         How many prohibited kills can take place before mission fails.
        4 _countIndirect    If false, only direct kills are counted. If true, all kills where _playerFaction is the instigator,
                            will be counted.
        5 _playerFaction    The faction which is prohibited (typically the player faction)
        
    OUTPUT:
        None
        
    NOTES:
        All the parameters except for the first one are shared between function calls. If you call the function
        multiple times (for multiple prohibited factions), keep parameters 2-5 constant. See EXAMPLES.
        
    EXAMPLES:
    
        Prohibit BLU_F from killing more than 5 members of CIV faction:
            ["CIV", false, 6, false, "BLU_F"] call qb_fnc_prohibitCivKilling;
        Prohibit BLU_F from killing any unarmed units (the faction name in 1st argument does not exist):
            ["UNARMED", true, 0, false, "BLU_F"] call qb_fnc_prohibitCivKilling;
        Prohibit BLU_F from killing any unarmed or any members of CIV faction. Count also indirect fire.
            ["CIV", true, 0, true, "BLU_F"] call qb_fnc_prohibitCivKilling;

        Multiple calls:
            This is OK:
                // Prohibit BLU_F from killing ANY members of CIV or IND_F or unarmed units.
                ["CIV", true, 0, false, "BLU_F"] call qb_fnc_prohibitCivKilling;
                ["IND_F", true, 0, false, "BLU_F"] call qb_fnc_prohibitCivKilling;
            This is not OK:
                // Prohibit BLU_F from killing ANY members of CIV or IND_F or unarmed units.
                ["CIV", true, 5, false, "BLU_F"] call qb_fnc_prohibitCivKilling;
                ["IND_F", true, 5, false, "OPF_F"] call qb_fnc_prohibitCivKilling; // param 5 changed between calls
                
    
    ### TODO: Allow multiple calls with varying params 2-5.
        
*/

private ["_faction", "_prohibitUnarmed", "_maxCount", "_countIndirect", "_playerFaction"];
private ["_countVarName"];

_faction = _this select 0;          // faction which should not be killed
_prohibitUnarmed = _this select 1;  // true/false: if killing unarmed is prohibited, too
_maxCount = _this select 2;         // max count of kills before mission end
_countIndirect = _this select 3;    // count indirect hits (e.g. same side AI)
_playerFaction = _this select 4;    // which faction is prohibited to kill _faction (or unarmed)

qb_cfg_prohibitCivKilling_debug = false;

qb_cfg_prohibitCivKilling_countVarName = "qb_fnc_prohibitCivKilling_count_" + _faction;
qb_cfg_prohibitCivKilling_countIndirect = _countIndirect;
qb_cfg_prohibitCivKilling_prohibitUnarmed = _prohibitUnarmed;
qb_cfg_prohibitCivKilling_faction = _faction;
qb_cfg_prohibitCivKilling_playerFaction = _playerFaction;
qb_cfg_prohibitCivKilling_maxCount = _maxCount;

missionNamespace setVariable [qb_cfg_prohibitCivKilling_countVarName, 0];
if (qb_cfg_prohibitCivKilling_debug) then { systemchat qb_cfg_prohibitCivKilling_countVarName; };

[] spawn {
    private ["_n"];
    while {true} do {
        sleep 5;
        _n = missionNamespace getVariable [qb_cfg_prohibitCivKilling_countVarName, 0];
        if (_n > qb_cfg_prohibitCivKilling_maxCount) then {
            if (qb_cfg_prohibitCivKilling_prohibitUnarmed) then {
                [[_n],{titletext [format ["You have killed too many (%1) non-armed persons or persons of prohibited faction. Mission failed.", _this select 0], "BLACK", 5];}] remoteExec ['call',0,false];
            } else {
                [[_n],{titletext [format ["You have killed too many (%1) persons of prohibited faction. Mission failed.", _this select 0], "BLACK", 5];}] remoteExec ['call',0,false];
            };
            sleep 5;
            ["LOSER"] remoteExec ["endMission", 0] ;
        };
    };
};

[] spawn {
    while {true} do {
        sleep 5;
        {
            private ["_isdone"];
            _isdone = _x getVariable ["qb_fnc_prohibitCivKilling_addKilledEH", false];
            
            if (not _isdone) then {
                //if (qb_cfg_prohibitCivKilling_debug) then { systemchat "add EH for kill"; };
                _x addEventHandler ["Killed", {
                    private ["_unit", "_killer", "_instigator"];
                    private ["_causer", "_harmDone", "_punish", "_count"];
                    _unit = _this select 0;
                    _killer = _this select 1;
                    _instigator = _this select 2;
                    
                    if (qb_cfg_prohibitCivKilling_debug) then { systemchat format ["kill factions: %1, %2, %3", faction _unit, faction _killer, faction _instigator]; };
                    
                    if (qb_cfg_prohibitCivKilling_countIndirect) then {
                        _causer = _instigator;
                    } else {
                        _causer = _killer;
                    };
                    
                    _harmDone = false;
                    
                    if (qb_cfg_prohibitCivKilling_prohibitUnarmed and (primaryWeapon _unit == "") and (secondaryWeapon _unit == "") and (currentWeapon _unit == "")) then {
                        if (qb_cfg_prohibitCivKilling_debug) then { systemchat "harm done (unarmed)"; };
                        if (isPlayer _causer) then {
                            ["Watch it! You are firing at unarmed persons!"] remoteExec ["hint", _causer];
                            //playSound configName(configfile >> "RadioProtocolENG" >> "Words" >> "Combat" >> "CheckYourFire");
                        };
                        _harmDone = true;
                    };
                    
                    if (faction _unit == qb_cfg_prohibitCivKilling_faction) then {
                        if (qb_cfg_prohibitCivKilling_debug) then { systemchat "harm done (proh faction)"; };
                        if (isPlayer _causer) then {
                            ["Watch it! You are causing collateral damage!"] remoteExec ["hint", _causer];
                            //playSound configName(configfile >> "RadioProtocolENG" >> "Words" >> "Combat" >> "CheckYourFire");
                        };
                        _harmDone = true;
                    };
                    
                    _punish = false;
                    if (qb_cfg_prohibitCivKilling_countIndirect) then {
                        if (_harmDone and ((faction _causer) == qb_cfg_prohibitCivKilling_playerFaction)) then {
                            if (qb_cfg_prohibitCivKilling_debug) then { systemchat "punish"; };
                            _punish = true;
                        };
                    } else {
                        if (_harmDone and ((faction _causer) == qb_cfg_prohibitCivKilling_playerFaction) and (isPlayer _causer)) then {
                            if (qb_cfg_prohibitCivKilling_debug) then { systemchat "punish"; };
                            _punish = true;
                        };
                    };
                    
                    if (_punish) then {
                        _count = missionNamespace getVariable [qb_cfg_prohibitCivKilling_countVarName, 0];
                        _count = _count + 1;
                        missionNamespace setVariable [qb_cfg_prohibitCivKilling_countVarName, _count];
                        if (qb_cfg_prohibitCivKilling_debug) then { systemchat format ["count %1: %2", qb_cfg_prohibitCivKilling_countVarName, _count]; };
                    };
                }];
                _x setVariable ["qb_fnc_prohibitCivKilling_addKilledEH", true];
            };
        } foreach allUnits;
    };
};
