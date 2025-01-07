#include "..\defines.inc"
FIX_LINE_NUMBERS()

Info("Skirmish frontline event Init.");

private _difficult = random 10 < tierWar;
private _difficult2 = random 10 < tierWar; ///maybe add a war level check, if high -> big battle

private _player = selectRandom (call SCRT_fnc_misc_getRebelPlayers);

if (isNil "_player") exitWith {
    Error("No players found, aborting.");
    isEventInProgress = false;
    publicVariableServer "isEventInProgress";
};

private _originPosition = position _player;
Info_2("%1 will be used as center of the event at %2 position.", name _player, str _originPosition);

/* private _potentialOutposts = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {
    sidesX getVariable [_x, sideUnknown] != teamPlayer && {(getMarkerPos _x) distance2D _player < distanceSPWN*5}
}; */
/* private _frontLine = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {([_x] call A3A_fnc_isFrontline && {sidesX getVariable [_x,sideUnknown] != teamPlayer}) && {(getMarkerPos _x) distance2D _player < distanceSPWN*2}};
diag_log _frontLine;
diag_log _frontLine;
diag_log _frontLine;
diag_log _frontLine;

diag_log _frontLine; */
private _frontLine = (outposts + milbases + airportsX + resourcesX + factories + citiesX) select {([_x] call A3A_fnc_isFrontlineNoFIA && {sidesX getVariable [_x,sideUnknown] != teamPlayer})};
private _frontlineSitesNearPlayer = ((outposts + milbases + airportsX + resourcesX + factories + citiesX) select {(_x in _frontLine) && {((getMarkerPos _x) distance2D _player < distanceSPWN*2.5) && {sidesX getVariable [_x,sideUnknown] != teamPlayer}}}) call BIS_fnc_arrayShuffle;

if (_frontlineSitesNearPlayer isEqualTo []) exitWith {
    Info("No outposts in proximity, aborting Skirmish fronline Event.");
    isEventInProgress = false;
    publicVariableServer "isEventInProgress";
};

private _FrontlineOutpost = selectRandom _frontlineSitesNearPlayer;

private _side = Occupants;
private _side2 = Invaders;
private _faction = Faction(_side);
private _faction2 = Faction(_side2);
private _FrontlineOutpostPosition = _originPosition ;//getMarkerPos _FrontlineOutpost;

private _specOpsArray = if (_difficult) then {selectRandom (_faction get "groupSpecOpsRandom")} else {selectRandom ([_faction, "groupsTierSquads"] call SCRT_fnc_unit_flattenTier)};     ///
private _specOpsArray2 = if (_difficult2) then {selectRandom (_faction2 get "groupSpecOpsRandom")} else {selectRandom ([_faction2, "groupsTierSquads"] call SCRT_fnc_unit_flattenTier)}; ///maybe move this into fuction and roll every time?

_skirmishposition = [_FrontlineOutpostPosition, distanceSPWN*0.7, distanceSPWN, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos; ///pos player , distance distance spwn
_skirmishposition2 = [_skirmishposition, 250, 350, 10, 0, 10, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;


private _fnc_spawngroups = {
	params ["_amount","_amount2", "_vehiclesAmount" , "_vehiclesAmount2" , "_difficult" , "_difficult2"];
	for "_i" from 1 to _amount do {
		_skirmishpositionActuall = [_skirmishposition, 40, 200, 10, 0, 5, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_InfGroup = [_skirmishpositionActuall, _side, _specOpsArray] call A3A_fnc_spawnGroup;
		{[_x] call A3A_fnc_NATOinit} forEach units _InfGroup;
		_InfGroup setBehaviourStrong "AWARE";
		private _wp = _InfGroup addWaypoint [_skirmishposition, 50];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		_InfGroups pushBack _InfGroup;
		private _vehicles = if (_difficult) then {selectRandom ((_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesTanks") + (_faction get "vehiclesAPCs") + (_faction get "vehiclesIFVs"))
					} else {selectRandom
					((_faction get "vehiclesLightUnarmed") + (_faction get "vehiclesLightArmed") + (_faction get "vehiclesAirborne") + (_faction get "vehiclesLightTanks") + (_faction get "vehiclesMilitiaAPCs") + 
					(_faction get "vehiclesMilitiaLightArmed") + (_faction get "vehiclesMilitiaCars"))
		};///add a check for a crew or vehicle type, if met order getout because weak vehicle or unarmed.
		diag_log _vehicles;
		_skirmishpositionActuallveh = [_skirmishpositionActuall, 10, 50, 10, 0, 5, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata = [_skirmishpositionActuallveh, 0, _vehicles, _side] call A3A_fnc_spawnVehicle;
		_vehicle = _vehicledata select 0;
		_vehiclegroup = _vehicledata select 2;
		[_vehicle, Occupants] call A3A_fnc_AIVEHinit;
		_vehiclegroup setBehaviourStrong "AWARE";
		units _vehiclegroup join _InfGroup;
		if (_difficult) then {
			_UAVtype = selectRandom (_faction get "uavsPortable");
			_uav = createVehicle [_UAVtype, _skirmishpositionActuall, [], 0, "FLY"];
			[_side, _uav] call A3A_fnc_createVehicleCrew;
			_vehiclesArray pushBack _uav;
			_groupUAV = group (crew _uav select 1);
			{[_x] joinSilent _InfGroup} forEach units _groupUAV;
		};
		[_InfGroup, "Patrol_Attack", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		[_vehiclegroup, "Patrol_Area", 0, 300, 1000, true, _skirmishposition, false] call A3A_fnc_patrolLoop;
		_vehiclesArray pushBack _vehicle;
	};
	for "_i" from 1 to _amount2 do {
		_skirmishpositionActuall2 = [_skirmishposition2, 100, 150, 10, 0, 5, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_InfGroup2 = [_skirmishpositionActuall2, _side2, _specOpsArray2] call A3A_fnc_spawnGroup;
		{[_x] call A3A_fnc_NATOinit} forEach units _InfGroup2;
		_InfGroup2 setBehaviourStrong "AWARE";
		private _wp = _InfGroup2  addWaypoint [_skirmishposition, 50];
		_wp setWaypointSpeed "NORMAL";
		_wp setWaypointType "SAD";
		_InfGroups2 pushBack _InfGroup2;

		private _vehicles2 = if (_difficult2) then {selectRandom ((_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesTanks") + (_faction2 get "vehiclesAPCs") + (_faction2 get "vehiclesIFVs"))
					} else {selectRandom
					((_faction2 get "vehiclesLightUnarmed") + (_faction2 get "vehiclesLightArmed") + (_faction2 get "vehiclesAirborne") + (_faction2 get "vehiclesLightTanks") + (_faction2 get "vehiclesMilitiaAPCs") + 
					(_faction2 get "vehiclesMilitiaLightArmed") + (_faction2 get "vehiclesMilitiaCars"))
		};
		diag_log _vehicles2;
		_skirmishpositionActuall2veh = [_skirmishpositionActuall2, 10, 50, 10, 0, 5, 0, [], [[0,0,0],[0,0,0]]] call BIS_fnc_findSafePos;
		_vehicledata2 = [_skirmishpositionActuall2veh, 0,_vehicles2, _side2] call A3A_fnc_spawnVehicle;
		_vehicle2 = _vehicledata2 select 0;
		_vehiclegroup2 = _vehicledata2 select 2;
		[_vehicle2, Invaders] call A3A_fnc_AIVEHinit;
		_vehiclegroup2 setBehaviourStrong "AWARE";
		units _vehiclegroup2 join _InfGroup2;
		/* if (_difficult2) then {
			_UAV2type = selectRandom (_faction2 get "uavsPortable");
			_uav2 = createVehicle [_UAV2type, _skirmishpositionActuall2, [], 0, "FLY"];
			[_side2, _uav2] call A3A_fnc_createVehicleCrew;
			_vehiclesArray2 pushBack _uav2;
			_groupUAV2 = group (crew _uav2 select 1);
			{[_x] joinSilent _InfGroup2} forEach units _groupUAV2;
		}; */ // for some reason, it can't create second uav
		[_InfGroup2, "Patrol_Attack", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		[_vehiclegroup2, "Patrol_Area", 0, 300, 1000, true, _skirmishposition, true] call A3A_fnc_patrolLoop;
		_vehiclesArray2 pushBack _vehicle2;
	};
};
private _amount = round random 3;
if (_amount == 0) then {
	_amount = 1;
};
private _amount2 = round random 3;
if (_amount2 == 0) then {
	_amount2 = 1;
};
private _vehiclesAmount = round random 3;
private _vehiclesAmount2 = round random 3;
private _InfGroups = [];
private _InfGroups2 = [];
private _vehiclesArray = [];
private _vehiclesArray2 = [];
private _vehicles = [];
[_amount, _amount2, _vehiclesAmount , _vehiclesAmount2 ,_difficult ,_difficult2] call _fnc_spawngroups;
///dissable AI and wait until players are nearby? or just wait until players are nearby and then spawn units
_vehicles append _vehiclesArray;
_vehicles append _vehiclesArray2;
private _friends = units _side inAreaArray [_skirmishposition, 1000, 1000];
private _friends2 = units _side2 inAreaArray [_skirmishposition, 1000, 1000];
private _friendGroups = allGroups select {(leader _x in _friends) and {isNull objectParent leader _x} };
private _friendGroups2 = allGroups select {(leader _x in _friends2) and {isNull objectParent leader _x} };

// Choose four random enemies to spot
private _allEnemiesSide1 = (units _side2) inAreaArray [_skirmishposition, 500, 500];
private _allEnemiesSide2 = (units _side) inAreaArray [_skirmishposition, 500, 500];
private _spottedEnemies = [];
private _spottedEnemies2 = [];
for "_i" from 0 to 3 do {
    if (count _allEnemiesSide1 == 0) exitWith {};
    private _index = floor random (count _allEnemiesSide1);
    _spottedEnemies pushBack (_allEnemiesSide1 # _index);
    _allEnemiesSide1 deleteAt _index;
	if (count _allEnemiesSide2 == 0) exitWith {};
    private _index2 = floor random (count _allEnemiesSide2);
    _spottedEnemies2 pushBack (_allEnemiesSide2 # _index2);
    _allEnemiesSide2 deleteAt _index2;
	{
        private _group = _x;
        //or: [[_group, _spottedEnemies], { { _this#0 reveal [_x, 2] } forEach _this#1 }] remoteExec ["call", leader _group];
        { [_group, [_x, 2]] remoteExec ["reveal", leader _group] } forEach _spottedEnemies;
    } forEach _InfGroups;
	{
        private _group = _x;
        //or: [[_group, _spottedEnemies], { { _this#0 reveal [_x, 2] } forEach _this#1 }] remoteExec ["call", leader _group];
        { [_group, [_x, 2]] remoteExec ["reveal", leader _group] } forEach _spottedEnemies2;
    } forEach _InfGroups2;
	sleep 60;
};

private _timeOut = time + 1800;
waitUntil {time > _timeOut && (call SCRT_fnc_misc_getRebelPlayers) inAreaArray [_skirmishposition, distanceSPWN1, distanceSPWN1] isEqualTo []};
/* _player distance2D _skirmishposition > 2000   */
///If someone survived -> move to base from the check above?
///some sort of check needed to delete groups and vehicles smart way
{[_x] spawn A3A_fnc_vehDespawner} forEach _vehicles;
{[_x] spawn A3A_fnc_groupDespawner} forEach _InfGroups;
{[_x] spawn A3A_fnc_groupDespawner} forEach _InfGroups2;

isEventInProgress = false;
publicVariableServer "isEventInProgress";

Info("Frontline skirmish clean up event complete.");