/*
    qb_fnc_setRespawnToAllGroups
    
    Simple helper functio which calls qb_fnc_setRespawnPoint on all groups of given side, automatically assigning a call sign.

    INPUT:
        1 _side           Side
        
    OUTPUT:
        None
        
*/

private ["_allGrps", "_grpCallNames", "_i", "_side"];
_grpCallNames = ["alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel", "india", "juliett", "kilo", "lima", 
"mike", "november", "oscar", "papa", "quebec", "romeo", "sierra", "tango", "uniform", "victor", "whiskey", "x-ray",
"yankee", "zulu"];

_side = _this select 0;

_allGrps = [];

{
    if ((side _x) == _side) then {
        _allGrps pushBackUnique (group _x);
    };
} forEach playableUnits;

_i = 0;
{
    [_x, _grpCallNames select _i, _side] call qb_fnc_setRespawnPoint;
    _i = _i + 1;
} forEach _allGrps;
