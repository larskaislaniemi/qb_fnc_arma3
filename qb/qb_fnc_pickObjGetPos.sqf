
_obj = _this select 0;
_pos = [0,0,0];

if (_obj getVariable ["pickObj_pickedUp", false]) then {
    _pos = getPos (_obj getVariable "pickObj_whoHas");
} else {
    _pos = getPos _obj;
};

_pos