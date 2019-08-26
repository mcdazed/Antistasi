params ["_destination", "_type", "_side", ["_arguments", []]];

/* params
*   _destination : MARKER or POS; the marker or position the AI should take AI on
*   _type : STRING; (not case sensitive) one of "ATTACK", "PATROL", "REINFORCE", "CONVOY", "AIRSTRIKE" more to add
*   _side : SIDE; the side of the AI forces to send
*   _arguments : ARRAY; any further argument needed for the operation
+        -here should be some manual for each _type
*/

if(isNil "_destination") exitWith {diag_log "CreateAIAction: No destination given for AI Action"};
_acceptedTypes = ["attack", "patrol", "reinforce", "convoy", "airstrike"];
if(isNil "_side" || {!((toLower _type) in _destination)}) exitWith {diag_log "CreateAIAction: Type is not in the accepted types"};
if(isNil "_side") exitWith {diag_log "CreateAIAction: Can only create AI for Inv and Occ"};

_convoyID = random 10000;
_IDinUse = server getVariable [_convoyID, false];
while {_IDinUse} do
{
  _convoyID = random 10000;
  _IDinUse = server getVariable [_convoyID, false];
};
server setVariable [_convoyID, true, true];

_type = toLower _type;
_isMarker = _destination isEqualType "";
_targetString = if(_isMarker) then {name _destination} else {str _destination};
diag_log format ["CreateAIAction[%1]: Started creation of %2 action to %3", _convoyID, _type, _targetString];

_nearestMarker = if(_isMarker) then {_destination} else {[markersX,_destination] call BIS_fnc_nearestPosition;}
if ([_nearestMarker,false] call A3A_fnc_fogCheck < 0.3) exitWith {diag_log format ["CreateAIAction[%1]: AI Action on %2 cancelled because of heavy fog", _convoyID, _targetString]};

_abort = false;
_attackDistance = distanceSPWN2;
if (_isMarker) then
{
  if(_destination in attackMrk) then {_abort = true};
  _destination = getMarkerPos _destination;
}
else
{
  if(count attackPos != 0) then
  {
    _nearestAttack = [attackPos, _destination] call BIS_fnc_nearestPosition;
    if ((_nearestAttack distance _destination) < _attackDistance) then {_abort = true;};
  }
  else
  {
    if(count attackMrk != 0) then
    {
      _nearestAttack = [attackMrk, _destination] call BIS_fnc_nearestPosition;
      if (getMarkerPos _nearestAttack distance _destination < _attackDistance) then {_abort = true};
    };
  };
};
if(_abort) exitWith {diag_log format ["CreateAIAction[%1]: Aborting creation of AI action because, there is already a action close by!", _convoyID]};

_sideConvoy = sidesX getVariable [_origin, sideUnknown];
if(_sideConvoy == sideUnknown) exitWith {diag_log "Marker has no side!"};

_originPos = getMarkerPos _origin;
_destinationPos = if(_destination isEqualType "") then {getMarkerPos _destination} else {_destination};
//Does this work like this?

_units = [];
_vehicleCount = 0;
_cargoCount = 0;
if(_type == "patrol") then
{

};
if(_type == "reinforce") then
{

};
if(_type == "attack") then
{

};
if(_type == "airstrike") then
{
  _airport = [_destination] call A3A_fnc_findAirportForAirstrike;
  if(!(isNil "_airport")) then
  {
    _friendlies = if (_side == Occupants) then
    {
      allUnits select
      {
        (alive _x) &&
        {((side (group _x) == _side) || (side (group _x) == civilian)) &&
        {_x distance _destinationPos < 200}}
      };
    }
    else
    {
      allUnits select
      {
        (side (group _x) == _side) &&
        {(_x distance _destinationPos < 100) &&
        {[_x] call A3A_fnc_canFight}}
      };
    };
    //NATO accepts 2 casulties, CSAT does not really care
    if((_side == Occupants && {count _friendlies < 3}) || {_side == Invaders && {count _friendlies < 8}}) then
    {
      _plane = if (_side == Occupants) then {vehNATOPlane} else {vehCSATPlane};
    	if ([_plane] call A3A_fnc_vehAvailable) then
    	{
        _type = "";
        if(count _arguments != 0) then
        {
          _type = _arguments select 0;
        }
        else
        {
          _distanceSpawn2 = distanceSPWN2;
          _enemies = allUnits select
          {
            (alive _x) &&
            {(_x distance _destinationPos < _distanceSpawn2) &&
            {(side (group _x) != _side) and (side (group _x) != civilian)}}
          };
          _type = if (napalmEnabled) then {"NAPALM"} else {"CLUSTER"};
    			{
    			  if (vehicle _x isKindOf "Tank") then
    				{
    				   _type = "HE" //Why should it attack tanks with HE?? TODO find better solution
    				}
    			  else
    				{
    				  if (vehicle _x != _x) then
    					{
    					  if !(vehicle _x isKindOf "StaticWeapon") then {_type = "CLUSTER"}; //TODO test if vehicle _x isKindOf Static is not also vehicle _x != _x
    					};
    				};
    			  if (_typeX == "HE") exitWith {};
    			} forEach _enemies;
        };
        if (!_isMarker) then {airstrike pushBack _destinationPos};
        diag_log format ["CreateAIAction[%1]: Selected airstrike of type %1 from %2",_convoyID, _type, name _airport];
        _originPos = getMarkerPos _airport;
        _units pushBack [_plane, []];
        _vehicleCount = 1;
        _cargoCount = 0;
      }
      else
      {
        diag_log format ["CreateAIAction[%1]: Aborting airstrike as the airplane is currently not available", _convoyID];
        _abort = true;
      };
    }
    else
    {
      diag_log format ["CreateAIAction[%1]: Aborting airstrike, cause there are too many friendly units in the area", _convoyID];
      _abort = true;
    };
  }
  else
  {
    diag_log format ["CreateAIAction[%1]: Aborting airstrike due to no avialable airport", _convoyID];
    _abort = true;
  };

};
if(_type == "convoy") then
{

};

if(_abort) exitWith {};

_target = if(_destination isEqualType "") then {name _destination} else {str _destination};
diag_log format ["CreateAIAction[%1]: Created AI action to %2 from %3 to %4 with %5 vehicles and %6 units", _convoyID, _type, name _origin, _target, _vehicleCount , _cargoCount];

[_convoyID, _units, _originPos, _destinationPos, _type, _sideConvoy] spawn A3A_fnc_createConvoy;
