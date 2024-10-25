params ["_markerX"];
//Mission: Conquer the outpost, before other faction will do it.
if (!isServer and hasInterface) exitWith{};
private _difficultX = if (random 10 < tierWar) then {true} else {false};
private _positionX = getMarkerPos _markerX;
private _limit = if (_difficultX) then {
	45 call SCRT_fnc_misc_getTimeLimit
} else {
	90 call SCRT_fnc_misc_getTimeLimit
};
_limit params ["_dateLimitNum", "_displayTime"];
private _markerSide = sidesX getVariable [_markerX, sideUnknown];
private _oppositeside = objNull;
if (_markerSide == Occupants) then {
	_oppositeside = Invaders;
} else {
	_oppositeside = Occupants;
};
private _nameDest = [_markerX] call A3A_fnc_localizar;
private _textX = "";
private _taskName = "";
if ((_oppositeside == Occupants && areOccupantsDefeated) || {(_oppositeside == Invaders && areInvadersDefeated)}) exitWith {
	[[_markerX],"A3A_fnc_CON_Outpost"] remoteExec ["A3A_fnc_scheduler",2];
};
switch (true) do {
	case (_markerX in resourcesX): {
		_textX = format [localize "STR_CON_Outpost_resources_compet_desc", _nameDest, _displayTime, _oppositeside]; ///add stringtables
		_taskName = localize "STR_CON_Outpost_resources_compet_task";
	};
	case (_markerX in controlsX): {
		_textX = format [localize "STR_CON_Outpost_controls_compet_desc", _nameDest, _displayTime, _oppositeside];
		_taskName = localize "STR_CON_Outpost_controls_compet_task";
	};
	default {
		_textX = format [localize "STR_CON_Outpost_outposts_compet_desc", _nameDest, _displayTime, _oppositeside];
		_taskName = localize "STR_CON_Outpost_outposts_compet_task";
	};
};
private _taskId = "CON" + str A3A_taskCount;
[[teamPlayer,civilian],_taskId,[_textX,_taskName,_markerX],_positionX,false,0,true,"Target",true] call BIS_fnc_taskCreate;
[_taskId, "CON", "CREATED"] remoteExecCall ["A3A_fnc_taskUpdate", 2];
private _delay = 30 + (round random 20);
private _targPos = markerPos _markerX;
private _airbase = [_oppositeside, markerPos _markerX] call A3A_fnc_availableBasesAir;
/* private _landbase = [_oppositeside, markerPos _markerX] call A3A_fnc_availableBasesLand;
private _allbases = selectRandom(_airbase + _landbase); */
private _vehCount = if (_difficultX) then {
	4;
} else {
	2;
};
if (_markerX in (airportsX + milbases)) then {
	_vehCount = 6;
};
//params ["_side", "_airbase", "_target", "_resPool", "_vehCount", "_delay", "_modifiers", "_attackType", "_reveal"];
/* private _data = [_oppositeside, _airbase, _targPos, "attack", _vehCount, _delay, ["tierboost"]] call A3A_fnc_createAttackForceMixed;
_data params ["_resources", "_vehicles", "_crewGroups", "_cargoGroups"]; */
[_markerX, _airbase, _vehCount] spawn A3A_fnc_wavedAttack;
// Prepare despawn conditions
private _endTime = time + 2700;
//private _victory = false;
/* private _soldiers = [];
{ _soldiers append units _x } forEach _cargoGroups; */
waitUntil {sleep 1; dateToNumber date > _dateLimitNum or {sidesX getVariable [_markerX,sideUnknown] == teamPlayer} /* || {sidesX getVariable [_markerX,sideUnknown] == _oppositeside} */};
/* while {true} do
{
    private _markerSide = sidesX getVariable _markerX;
    if(_markerSide == _oppositeside) exitWith {
        //diag_log ("Attack to %1 captured the marker, starting despawn routines", _markerX);
        _victory = true;
    };
    private _curSoldiers = { !fleeing _x and _x call A3A_fnc_canFight } count _soldiers;
    if (_curSoldiers < count _soldiers * 0.25) exitWith {
        //diag_log ("Small attack to %1 has been defeated, starting despawn routines", _markerX);
    };
    if(_endTime < time) exitWith {
       // diag_log ("Small attack to %1 timed out, starting despawn routines", _markerX);
    };
    // Attempt to flip marker
    [_markerX, _markerSide] remoteExec ["A3A_fnc_zoneCheck", 2];
    sleep 30;
}; */
/* { [_x] spawn A3A_fnc_VEHDespawner } forEach _vehicles;
{ [_x] spawn A3A_fnc_enemyReturnToBase } forEach _crewGroups;
{
    [_x, [nil, _markerX] select _victory] spawn A3A_fnc_enemyReturnToBase;
    sleep 10;
} forEach _cargoGroups; */
// add a check if all players are dead, in the area of a marker
// Or add a check if possible to determite whenver other faction managed to capture marker, or leave it as is
if (dateToNumber date > _dateLimitNum) then { ///here we need to add check if defenders or players in the area are dead or if there are more attackers then defenders
	[_taskId, "CON", "FAILED"] call A3A_fnc_taskSetState;
	if (_difficultX) then {
		[25,0,_positionX] remoteExec ["A3A_fnc_citySupportChange",2];
		[-1200, _markerSide] remoteExec ["A3A_fnc_timingCA",2];
		[-20,theBoss] call A3A_fnc_addScorePlayer;
		//[_oppositeside, _markerX] spawn A3A_fnc_markerChange;
	} else {
		[5,0,_positionX] remoteExec ["A3A_fnc_citySupportChange",2];
		[-600, _markerSide] remoteExec ["A3A_fnc_timingCA",2];
		[-10,theBoss] call A3A_fnc_addScorePlayer;
		//[_oppositeside, _markerX] spawn A3A_fnc_markerChange;
	};
} else {
	sleep 10;
	[_taskId, "CON", "SUCCEEDED"] call A3A_fnc_taskSetState;
	if (_difficultX) then {
		[0,800] remoteExec ["A3A_fnc_resourcesFIA",2];
		[-25,0,_positionX] remoteExec ["A3A_fnc_citySupportChange",2];
		[1800, _markerSide] remoteExec ["A3A_fnc_timingCA",2];
		{ 
			[450, _x] call A3A_fnc_addMoneyPlayer;
			[30, _x] call A3A_fnc_addScorePlayer;
		} forEach (call SCRT_fnc_misc_getRebelPlayers);
		[30, theBoss] call A3A_fnc_addScorePlayer;
        [300,theBoss, true] call A3A_fnc_addMoneyPlayer;
	} else {
		[0,600] remoteExec ["A3A_fnc_resourcesFIA",2];
		[-20,0,_positionX] remoteExec ["A3A_fnc_citySupportChange",2];
		[1200, _markerSide] remoteExec ["A3A_fnc_timingCA",2];
		{ 
			[250, _x] call A3A_fnc_addMoneyPlayer;
			[20, _x] call A3A_fnc_addScorePlayer;
		} forEach (call SCRT_fnc_misc_getRebelPlayers);
		[20, theBoss] call A3A_fnc_addScorePlayer;
        [200, theBoss, true] call A3A_fnc_addMoneyPlayer;
	};
};
[_taskId, "CON", 1200] spawn A3A_fnc_taskDelete;
