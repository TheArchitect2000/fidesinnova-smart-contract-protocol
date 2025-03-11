
// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import {AccessManagers} from "./utils/AccessManagers.sol";

struct Device {
string nodeId;
string deviceId;
string ownerId;
string name;
string deviceType;
string encryptedID;
string hardwareVersion;
string firmwareVersion;
string[] parameters;
string useCost;
string[] locationGPS;
string installationDate;
}

contract SharedDevice is AccessManagers {
/**********************************************************************************************/
/*** errors ***/
/**********************************************************************************************/
error SharedDevice__DuplicatedId(string nodeId, string deviceId);
error SharedDevice__DeviceIdNotExist(string nodeId, string deviceId);

/**********************************************************************************************/
/*** constructor ***/
/**********************************************************************************************/

constructor(address initialOwner) AccessManagers(initialOwner) {}

/**********************************************************************************************/
/*** Storage ***/
/**********************************************************************************************/

/// @dev Mapping of device id to device
mapping(uint256 id => Device device) private s_devices;

/// @dev Find ID of a device by its node id and device id
mapping(string nodeId => mapping(string deviceId => uint256 id)) s_deviceFindId;

uint256 s_deviceDatabaseId = 1;

/// @dev Array of existing devices
uint256[] private s_deviceIDs;

/**********************************************************************************************/
/*** events ***/
/**********************************************************************************************/

event DeviceCreated(uint256 indexed id, Device device);
event DeviceRemoved(uint256 indexed id, Device device);

/**********************************************************************************************/
/*** external functions ***/
/**********************************************************************************************/

/*
* @notice This function creates a new device
*/
function createDevice(
string memory nodeId,
string memory deviceId,
string memory ownerId,
string memory name,
string memory deviceType,
string memory encryptedID,
string memory hardwareVersion,
string memory firmwareVersion,
string[] memory parameters,
string memory useCost,
string[] memory locationGPS,
string memory installationDate
) external onlyManager returns (uint256) {
/// @dev Duplicate ID error handling
if (s_deviceFindId[nodeId][deviceId] != 0) {
revert SharedDevice__DuplicatedId(nodeId, deviceId);
}
s_deviceFindId[nodeId][deviceId] = s_deviceDatabaseId;
s_devices[s_deviceDatabaseId] = Device(
nodeId,
deviceId,
ownerId,
name,
deviceType,
encryptedID,
hardwareVersion,
firmwareVersion,
parameters,
useCost,
locationGPS,
installationDate
);
s_deviceIDs.push(s_deviceDatabaseId);

emit DeviceCreated(s_deviceDatabaseId, s_devices[s_deviceDatabaseId]);
s_deviceDatabaseId++;
return s_deviceDatabaseId;
}

/*
* @notice This function removes a device by its id
*/
function removeDevice(
string memory targetNodeId,
string memory targetDeviceId
) external onlyManager {
if (s_deviceFindId[targetNodeId][targetDeviceId] == 0) {
revert SharedDevice__DeviceIdNotExist(targetNodeId, targetDeviceId);
}

uint256 targetId = s_deviceFindId[targetNodeId][targetDeviceId];
uint256[] memory tempIDs = s_deviceIDs;
/// @dev Removing the target ID from the IDs array
for (uint256 i; i < tempIDs.length; i++) {
if (tempIDs[i] == targetId) {
s_deviceIDs[i] = s_deviceIDs[s_deviceIDs.length - 1];
s_deviceIDs.pop();
break;
}
}

s_deviceFindId[targetNodeId][targetDeviceId] = 0;

emit DeviceRemoved(targetId, s_devices[targetId]);

/// @dev Removing the target device from the devices mapping
delete (s_devices[targetId]);
}

/*
* @notice Returns all the existing devices as an array
*/
function fetchAllDevices()
external
view
onlyManager
returns (Device[] memory)
{
Device[] memory dataArray = new Device[](s_deviceIDs.length);
for (uint256 i = 0; i < s_deviceIDs.length; i++) {
dataArray[i] = s_devices[s_deviceIDs[i]];
}
return dataArray;
}
}
