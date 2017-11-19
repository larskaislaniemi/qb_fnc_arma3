_mode = _this select 0;
_params = _this select 1;

if (_mode == "enable") then {
    _obj = _params select 0;
    _obj setVariable ["trh_beacon_enabled", true];
    
    [_params] spawn {
        _params = _this select 0;
        _obj = _params select 0;
        _uncert = _params select 1; 
        _pingtime = _params select 2; 
        _markerName = _params select 3;
        
        while {_obj getVariable ["trh_beacon_enabled", false]} do {
            _pos = [_obj, _uncert/2.0] call qb_fnc_getPosNearObject;
            createMarker [_markerName, _pos];
            _markerName setMarkerShape "ELLIPSE";
            _markerName setMarkerBrush "Solid";
            _markerName setMarkerSize [_uncert, _uncert];
            _markerName setMarkerAlpha 0.5;
            _markerName setMarkerColor "ColorRed";
            sleep _pingtime;            
            deleteMarker _markerName;
        };
    };
};

if (_mode == "disable") then {
    _obj = _params select 0;
    _obj setVariable ["trh_beacon_enabled", false];
};