/*
    qb_fnc_knowsAboutSide
    
    Tests whether an object or a group knows about any unit of a given side.
        
    INPUT:
        1 _objgrp          Object or group which knowledge of _enemySide is being tested
        2 _enemySide       Enemy side
        
    OUTPUT:
        Largest "knows about" value (between 0-4, see https://community.bistudio.com/wiki/knowsAbout) about the enemy side.
        
*/

private ["_objgrp", "_enemyside"];
_objgrp = _this select 0;
_enemyside = _this select 1;

_val = 0;

{
    if (side _x == _enemyside) then {
        if (_objgrp knowsAbout _x > _val) then {
            _val = _objgrp knowsAbout _x;
        };
    };
} forEach allUnits;

_val