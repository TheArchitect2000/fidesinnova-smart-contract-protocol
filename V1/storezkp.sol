// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract ZKPStorage {
// Struct to hold the ZKP information
struct ZKP {
string nodeId;
string deviceId;
string deviceType;
string hardwareVersion;
string firmwareVersion;
string data_payload;
string zkp_payload;
string unixtime_payload;
uint256 timestamp; // Timestamp when the data is stored
}

// Array to store all ZKP entries
ZKP[] public zkps;

// Event to be emitted when a new ZKP is stored
event ZKPStored(
string nodeId,
string deviceId,
string deviceType,
string hardwareVersion,
string firmwareVersion,
string data_payload,
string zkp_payload,
string unixtime_payload,
uint256 timestamp
);

// Function to store a new ZKP
function storeZKP(
string memory nodeId,
string memory deviceId,
string memory deviceType,
string memory hardwareVersion,
string memory firmwareVersion,
string memory zkp_payload,
string memory data_payload,
string memory unixtime_payload

) public {
// Create a new ZKP struct and store it in the array
zkps.push(ZKP({
nodeId: nodeId,
deviceId: deviceId,
deviceType: deviceType,
hardwareVersion: hardwareVersion,
firmwareVersion: firmwareVersion,
zkp_payload: zkp_payload,
data_payload: data_payload,
unixtime_payload: unixtime_payload,
timestamp: block.timestamp
}));

// Emit the event for the new ZKP
emit ZKPStored(nodeId, deviceId, deviceType, hardwareVersion, firmwareVersion, zkp_payload, data_payload, unixtime_payload, block.timestamp);
}

// Function to get the number of ZKP entries
function getZKPCount() public view returns (uint256) {
return zkps.length;
}

// Function to retrieve a specific ZKP by index
function getZKP(uint256 index) public view returns (
string memory nodeId,
string memory deviceId,
string memory deviceType,
string memory hardwareVersion,
string memory firmwareVersion,
string memory zkp_payload,
string memory data_payload,
string memory unixtime_payload,
uint256 timestamp
) {
require(index < zkps.length, "Index out of bounds");

ZKP storage zkp = zkps[index];
return (zkp.nodeId, zkp.deviceId, zkp.deviceType, zkp.hardwareVersion, zkp.firmwareVersion, zkp.zkp_payload, zkp.data_payload, zkp.unixtime_payload, zkp.timestamp);
}
}