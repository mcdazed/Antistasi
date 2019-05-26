private ["_marcador","_pos","_airportsAAF","_airportsX","_base","_posbase","_busy","_lado"];

_marcador = _this select 0;
_pos = getMarkerPos _marcador;
_lado = lados getVariable [_marcador,sideUnknown];

_airportsAAF = (airportsX + puestos) select {(spawner getVariable _x == 2) and (dateToNumber date > server getVariable _x) and ([_x,_marcador] call A3A_fnc_isTheSameIsland) and (!(_x in forcedSpawn)) and (lados getVariable [_x,sideUnknown] == _lado) and !(_x in blackListDest) and (getMarkerPos _x distance _pos > distanceSPWN)};
if (_marcador in citiesX) then {_airportsAAF = _airportsAAF select {lados getVariable [_x,sideUnknown] == malos}};
_airportsX = [];
_base = "";
{
_base = _x;
_posbase = getMarkerPos _base;
if ((_pos distance _posbase < distanceForLandAttack) and (({_x == _marcador} count (killZones getVariable [_base,[]])) < 3)) then {_airportsX pushBack _base}
} forEach _airportsAAF;
if (count _airportsX > 0) then {_base = [_airportsX,_pos] call BIS_fnc_nearestPosition} else {_base = ""};
_base