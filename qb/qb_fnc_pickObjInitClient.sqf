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
        /*
        player addEventHandler ["Hit", {
            _unit = _this select 0;
            
            if ((lifeState _unit == "HEALTHY") OR (lifeState _unit == "INJURED")) then {
                // Nothing to be done
            } else {
                _obj = _unit getVariable ["pickObj_obj", objNull];
                if (not isNull _obj) then {        
                    _unit addAction [format ["Take %1", _obj getVariable "pickObj_name"], {
                        _target = _this select 0; // the dead unit
                        _caller = _this select 1; // the one who takes the object
                        _id = _this select 2;
                        _obj = (_this select 3) select 0;
                        
                        _pickedup = _obj getVariable "pickObj_pickedUp";
                        _whohasit = _obj getVariable "pickObj_whoHas";
                        
                        if ((not isNil "_pickedup") and (_pickedup)) then {
                            if ((not isNil "_whohasit") and (_whohasit == _target)) then {
                                //_obj setVariable ["pickObj_pickedUp", false, true];
                                //_obj setvariable ["pickObj_whoHas", 0, true]; // leave untouched to record previous owner
                                _obj setVariable ["pickObj_pickedUp", true, true];
                                _obj setvariable ["pickObj_whoHas", _caller, true]; // new owner
                            };
                        };
                        
                    }, [_obj], 6, true, true, "", "true", 6, false, ""];
                };
            };
        }];
        */
        _actId = _obj addAction ["pick up " + (_obj getVariable "pickObj_name"), {
            private ["_obj", "_unit", "_actId", "_evtId"];
            _obj = _this select 0;
            _unit = _this select 1;
            _obj setVariable ["pickObj_whoHas", _unit, true];
            _obj setVariable ["pickObj_pickedUp", true, true];
            _unit setVariable ["pickObj_obj", _obj, true];

            [ _obj, false ] remoteExec ["enableSimulation", 0, false];
            _obj setPosATL [0,0,0];
            
            _actId = _unit addAction ["drop " + (_obj getVariable "pickObj_name"), {
                private ["_target", "_caller", "_id", "_args", "_obj"];
                
                _target = _this select 0;
                _caller = _this select 1;
                _id = _this select 2;
                _args = _this select 3;
                _obj = _args select 0;
                
                if (side _target != side _caller) exitWith {};
                
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
};