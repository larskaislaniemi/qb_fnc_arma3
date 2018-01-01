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
        3 _pickAction     Code called when object is picked up
        4 _dropAction     Code called when object is dropped
        
    OUTPUT:
        None
        
    Pick and drop actions are passed one parameter, the object.
        
*/

if (!isServer) exitWith { false };

private ["_actId", "_playerCode", "_ret"];

params ["_obj", "_name", ["_pickAction", {true}], ["_dropAction", {true}]];

_obj setVariable ["pickObj_name", _name, true];
_obj setVariable ["pickObj_pickedUp", false, true];
_obj setvariable ["pickObj_whoHas", 0, true];
_obj setVariable ["pickObj_pickAction", _pickAction, true];
_obj setVariable ["pickObj_dropAction", _dropAction, true];
_obj enableSimulationGlobal true;

[[_obj], qb_fnc_pickObjInitClient] remoteExec ["call", 0, true];
