/*
    qb_fnc_pickObjForceDrop

    Force whoever has the object to drop it
    
    INPUT:
        1 _obj            Object to make pickable.
        
    OUTPUT:
        None
        
*/

_obj = _this select 0;

if (!isNull _obj) then {
    detach _obj;
    if (_obj getVariable ["pickObj_pickedUp", false]) then {
        _unit = _obj getVariable ["pickObj_whoHas", objNull];
        if (!isNull _unit) then {
            _unit setVariable ["pickObj_obj", objNull, true];
        };
        _actid = _unit getVariable ["pickObj_unitDropActId", -1];
        if (_actid != -1) then { _unit removeAction _actid; };
        _pos = [getPos _unit, 1] call qb_fnc_getPosNearPos;
        _obj setVariable ["pickObj_whoHas", objNull, true];
        _obj setVariable ["pickObj_pickedUp", false, true];
        _obj setPos _pos;
    };
};

