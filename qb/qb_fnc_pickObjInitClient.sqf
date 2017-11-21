/*
    qb_fnc_pickObjInitClient
    
    Internal routines for 'qb_fnc_pickObjInit'.
    DO NOT call directly. Instead, call 'qb_fnc_pickObjInit' on server.
        
*/

if (hasInterface) then {
    waitUntil { not isNull player };

    private ["_obj"];
    _obj = _this select 0;
    
    [_obj] spawn {
        private ["_obj", "_actId"];
        _obj = _this select 0;

        player addEventHandler ["Killed", {
            private ["_obj", "_pickedup", "_whohasit", "_me"];
            _me = _this select 0;
            _obj = _me getVariable ["pickObj_obj", objNull];
            if (not isNull _obj) then {
                _pickedup = _obj getVariable "pickObj_pickedUp";
                _whohasit = _obj getVariable "pickObj_whoHas";
                if ((not isNil "_pickedup") and (_pickedup)) then {
                    if ((not isNil "_whohasit") and (_whohasit == player)) then {
                        detach _obj;
                        _obj setVariable ["pickObj_pickedUp", false, true];
                        //_obj setvariable ["pickObj_whoHas", 0, true]; // leave untouched to record previous owner
                        _newPos = [_me, 0.5] call qb_fnc_getPosNearObject;
                        _newPos set [2, (getPosATL _me) select 2];
                        _obj setPosATL _newPos;
                        [ _obj, true ] remoteExec ["enableSimulation", 0, false];
                    };
                };
            };
            _me removeAction (_me getVariable ["pickObj_unitDropActId", -1]);
            _me setVariable ["pickObj_unitDropActId", -1];
        }];

        player addEventHandler ["Hit", {
            private ["_obj", "_pickedup", "_whohasit", "_me"];
            _me = _this select 0;
            if (lifeState _me == "INCAPACITATED") then {
                _obj = _me getVariable ["pickObj_obj", objNull];
                if (not isNull _obj) then {
                    _pickedup = _obj getVariable "pickObj_pickedUp";
                    _whohasit = _obj getVariable "pickObj_whoHas";
                    if ((not isNil "_pickedup") and (_pickedup)) then {
                        if ((not isNil "_whohasit") and (_whohasit == player)) then {
                            detach _obj;
                            _obj setVariable ["pickObj_pickedUp", false, true];
                            //_obj setvariable ["pickObj_whoHas", 0, true]; // leave untouched to record previous owner
                            _newPos = [_me, 0.5] call qb_fnc_getPosNearObject;
                            _newPos set [2, (getPosATL _me) select 2];
                            _obj setPosATL _newPos;
                            [ _obj, true ] remoteExec ["enableSimulation", 0, false];
                        };
                    };
                };
                _me removeAction (_me getVariable ["pickObj_unitDropActId", -1]);
                _me setVariable ["pickObj_unitDropActId", -1];
            };
        }];

        _actId = _obj addAction ["<t color='#ff0000'>Pick up " + (_obj getVariable "pickObj_name") + "</t>", {
            private ["_obj", "_unit", "_actId", "_evtId"];
            _obj = _this select 0;
            _unit = _this select 1;
            _obj setVariable ["pickObj_whoHas", _unit, true];
            _obj setVariable ["pickObj_pickedUp", true, true];
            _unit setVariable ["pickObj_obj", _obj, true];

            [ _obj, false ] remoteExec ["enableSimulation", 0, false];
            _obj setPosATL [0,0,0];
            
            detach _obj;
            _dims = boundingBoxReal trh_treasure;
            _dims1 = _dims select 0;
            _dims2 = _dims select 1;
            _maxWidth = abs((_dims1 select 1)-(_dims2 select 1));
            _obj attachTo [player, [0, -(_maxWidth/2.0+0.2), 0], "Pelvis"];
            
            _actId = _unit addAction ["<t color='#ff0000'>Drop " + (_obj getVariable "pickObj_name") + "</t>", {
                private ["_target", "_caller", "_id", "_args", "_obj"];
                
                _target = _this select 0;
                _caller = _this select 1;
                _id = _this select 2;
                _args = _this select 3;
                _obj = _args select 0;
                
                if (side _target != side _caller) exitWith {};
                
                detach _obj;
                
                _obj setVariable ["pickObj_pickedUp", false, true];
                //_obj setvariable ["pickObj_whoHas", 0, true]; // leave untouched to record previous owner
                _newPos = [_caller, 0.5] call qb_fnc_getPosNearObject;
                _newPos set [2, (getPosATL _caller) select 2];
                _obj setPosATL _newPos;
                [ _obj, true ] remoteExec ["enableSimulation", 0, false];
                //{(player getVariable "pickObj_obj") enableSimulation true;} remoteExec ["bis_fnc_call", 0, false];
                
                _target removeAction _id;
                _target setVariable ["pickObj_obj", objNull, true];
            }, [_obj], 0, false, true, "", "true"];
            _unit setVariable ["pickObj_unitDropActId", _actId];
            
        }, [], 5, true, true, "", "true"];
    };
    
    [_obj] spawn {
        _obj = _this select 0;
        while { true } do {
            waitUntil { player getVariable ["pickObj_obj", objNull] == _obj };
            _layer = "pickObj_infoLayer" call BIS_fnc_rscLayer;
            _layer cutText [format ["<t color='#ff0000'>You are carrying the %1</t>", _obj getVariable "pickObj_name"], "PLAIN DOWN", -1, true, true];
            // see also cutRsc
            waitUntil { player getVariable ["pickObj_obj", objNull] != _obj };
            _layer cutText [format ["<t color='#ff0000'>You dropped the %1</t>", _obj getVariable "pickObj_name"], "PLAIN DOWN", -1, true, true];
        };
    };
};