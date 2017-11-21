/*
    qb_fnc_getPosNearMarker
    
    Get a random position within radius _range from marker _mrk.

    INPUT:
        1 _mrk    Marker
        2 _range  Range
        
    OUTPUT:
        2D Position
           
*/

private ["_mrk", "_setPos", "_range", "_dir"];
_mrk = _this select 0;
_range = _this select 1;
_setPos = getMarkerPos _mrk;
_dir = random 360;
_range = random _range;
_setPos = [(_setPos select 0)+_range*sin(_dir), (_setPos select 1)+_range*cos(_dir), 0];
_setPos