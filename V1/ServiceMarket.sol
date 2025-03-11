

// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import {SharedDevice} from "./SharedDevice.sol";

struct Service {
string nodeId;
string serviceId;
string name;
string description;
string serviceType;
string devices;
string installationPrice;
string executionPrice;
string imageURL;
string program;
string creationDate;
string publishedDate;
}

contract ServiceMarket is SharedDevice {
/**********************************************************************************************/
/*** errors ***/
/**********************************************************************************************/
error ServiceMarket__DuplicatedId(string nodeId, string serviceId);
error ServiceMarket__ServiceIdNotExist(string nodeId, string serviceId);

/**********************************************************************************************/
/*** constructor ***/
/**********************************************************************************************/

constructor(address initialOwner) SharedDevice(initialOwner) {}

/**********************************************************************************************/
/*** Storage ***/
/**********************************************************************************************/

/// @dev Mapping of service id to service
mapping(uint256 id => Service service) private s_services;

/// @dev Find ID of a service by its node id and service id
mapping(string nodeId => mapping(string serviceId => uint256 id)) s_serviceFindId;

uint256 s_serviceDatabaseId = 1;

/// @dev Array of existing services
uint256[] private s_serviceIDs;

/**********************************************************************************************/
/*** events ***/
/**********************************************************************************************/

event ServiceCreated(uint256 indexed id, Service service);
event ServiceRemoved(uint256 indexed id, Service service);

/**********************************************************************************************/
/*** external functions ***/
/**********************************************************************************************/

/*
* @notice This function creates a new service
*/
function createService(
string memory nodeId,
string memory serviceId,
string memory name,
string memory description,
string memory serviceType,
string memory devices,
string memory installationPrice,
string memory executionPrice,
string memory imageURL,
string memory program,
string memory creationDate,
string memory publishedDate
) external onlyManager returns (uint256) {
/// @dev Duplicate ID error handling
if (s_serviceFindId[nodeId][serviceId] != 0) {
revert ServiceMarket__DuplicatedId(nodeId, serviceId);
}
s_serviceFindId[nodeId][serviceId] = s_serviceDatabaseId;
s_services[s_serviceDatabaseId] = Service(
nodeId,
serviceId,
name,
description,
serviceType,
devices,
installationPrice,
executionPrice,
imageURL,
program,
creationDate,
publishedDate
);
s_serviceIDs.push(s_serviceDatabaseId);

emit ServiceCreated(
s_serviceDatabaseId,
s_services[s_serviceDatabaseId]
);
s_serviceDatabaseId++;
return s_serviceDatabaseId;
}

/*
* @notice This function removes a service by its id
* @dev IDs are stored in a separate array to handle the removal process correctly
*/
function removeService(
string memory targetNodeId,
string memory targetServiceId
) external onlyManager {
if (s_serviceFindId[targetNodeId][targetServiceId] == 0) {
revert ServiceMarket__ServiceIdNotExist(
targetNodeId,
targetServiceId
);
}

uint256 targetId = s_serviceFindId[targetNodeId][targetServiceId];
uint256[] memory tempIDs = s_serviceIDs;
/// @dev Removing the target ID from the IDs array
for (uint256 i; i < tempIDs.length; i++) {
if (tempIDs[i] == targetId) {
s_serviceIDs[i] = s_serviceIDs[s_serviceIDs.length - 1];
s_serviceIDs.pop();
break;
}
}

s_serviceFindId[targetNodeId][targetServiceId] = 0;

emit ServiceRemoved(targetId, s_services[targetId]);

/// @dev Removing the target service from services mapping
delete (s_services[targetId]);
}

/*
* @notice Returns all the existing services as an array
*/
function fetchAllServices()
external
view
onlyManager
returns (Service[] memory)
{
Service[] memory dataArray = new Service[](s_serviceIDs.length);
for (uint256 i = 0; i < s_serviceIDs.length; i++) {
dataArray[i] = s_services[s_serviceIDs[i]];
}
return dataArray;
}
}


