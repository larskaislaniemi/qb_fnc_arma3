/*
    qb_fnc_pickObjInit

    Makes any object pickable and droppable.
    
    An unit can pick the object and (virtually) carry it with him. The object will have an "pick up" action and once a unit
    is carrying the object, he will have a "drop" action. The object will be automatically dropped when unit dies.
    
    Notes:
        1) The object is only virtually carried. The implementation puts the object at coordinates [0,0,0] when it is being
           carried. Also, the object does not increase unit's inventory weight.
        2) Only one pickable object per mission is currently possible.
        
    INPUT:
        1 _obj            Object to make pickable.
        2 _name           Name for the object (shown in action menu)
        
    OUTPUT:
        None
        
*/

if (!isServer) exitWith { false };

private ["_obj", "_name", "_actId", "_playerCode", "_ret"];

_obj = _this select 0;
_name = _this select 1;

_obj setVariable ["pickObj_name", _name, true];
_obj setVariable ["pickObj_pickedUp", false, true];
_obj setvariable ["pickObj_whoHas", 0, true];
_obj enableSimulationGlobal true;

[[_obj], qb_fnc_pickObjInitClient] remoteExec ["call", 0, true];
