/*
    qb_fnc_getPosNearPos
    
    Get a random position within given range from given position.

    INPUT:
        1 _pos    Position
        2 _range  Range
        
    OUTPUT:
        2D Position

*/

private ["_pos", "_setPos", "_range", "_dir"];
_pos = _this select 0;
_range = _this select 1;
_dir = random 360;
_rangeProb = sqrt (random 1.0);
_range = _range * _rangeProb;
_setPos = [(_pos select 0)+_range*sin(_dir), (_pos select 1)+_range*cos(_dir), (_pos select 2)];
_setPos