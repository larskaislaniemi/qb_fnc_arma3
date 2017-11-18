/*
    qb_fnc_getPosNearObject
    
    Get a random position within given range from given object.

    INPUT:
        1 _obj    Object
        2 _range  Range
        
    OUTPUT:
        2D Position

*/

private ["_obj", "_setPos", "_range", "_dir"];
_obj = _this select 0;
_range = _this select 1;
_setPos = getPos _obj;
_dir = random 360;
_range = random _range;
_setPos = [(_setPos select 0)+_range*sin(_dir), (_setPos select 1)+_range*cos(_dir), (_setPos select 2)];
_setPos