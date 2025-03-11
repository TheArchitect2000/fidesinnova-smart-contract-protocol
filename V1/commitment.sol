// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract CommitmentStorage {
// Struct to hold the Commitment information
struct Commitment {
string commitmentID; // Unique ID for each commitment as a string
string nodeId;
string iot_manufacturer_name;
string iot_device_name;
string device_hardware_version;
string firmware_version;
string commitmentData;
uint256 timestamp; // Timestamp when the data is stored
}

// Array to store all Commitment entries
Commitment[] public commitments;

// Mapping to track commitment IDs to ensure uniqueness
mapping(string => bool) public commitmentIDs;

event CommitmentStored(
string commitmentID,
string nodeId,
string iot_manufacturer_name,
string iot_device_name,
string device_hardware_version,
string firmware_version,
string commitmentData,
uint256 timestamp
);

event CommitmentRemoved(string commitmentID, string nodeId, uint256 timestamp);

// Function to store a new Commitment
function storeCommitment(
string memory commitmentID,
string memory nodeId,
string memory iot_manufacturer_name,
string memory iot_device_name,
string memory device_hardware_version,
string memory firmware_version,
string memory commitmentData
) public returns (bool) {
// Check if the commitmentID already exists
if (commitmentIDs[commitmentID]) {
revert("CommitmentID already registered");
}

// Create a new Commitment struct and store it in the array
commitments.push(Commitment({
commitmentID: commitmentID,
nodeId: nodeId,
iot_manufacturer_name: iot_manufacturer_name,
iot_device_name: iot_device_name,
device_hardware_version: device_hardware_version,
firmware_version: firmware_version,
commitmentData: commitmentData,
timestamp: block.timestamp
}));

// Mark this commitmentID as registered
commitmentIDs[commitmentID] = true;

// Emit the event for the new Commitment
emit CommitmentStored(
commitmentID,
nodeId,
iot_manufacturer_name,
iot_device_name,
device_hardware_version,
firmware_version,
commitmentData,
block.timestamp
);

return true;
}

// Function to retrieve a specific Commitment by commitmentID and nodeId
function getCommitment(string memory commitmentID, string memory nodeId) public view returns (
string memory commitmentIDResult,
string memory nodeIdResult,
string memory iot_manufacturer_name,
string memory iot_device_name,
string memory device_hardware_version,
string memory firmware_version,
string memory commitmentData,
uint256 timestamp
) {
for (uint256 i = 0; i < commitments.length; i++) {
if (keccak256(abi.encodePacked(commitments[i].commitmentID)) == keccak256(abi.encodePacked(commitmentID)) &&
keccak256(abi.encodePacked(commitments[i].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
Commitment storage commitment = commitments[i];
return (
commitment.commitmentID,
commitment.nodeId,
commitment.iot_manufacturer_name,
commitment.iot_device_name,
commitment.device_hardware_version,
commitment.firmware_version,
commitment.commitmentData,
commitment.timestamp
);
}
}
revert("Commitment not found");
}

// Function to remove a Commitment by commitmentID and nodeId
function removeCommitment(string memory commitmentID, string memory nodeId) public {
for (uint256 i = 0; i < commitments.length; i++) {
if (keccak256(abi.encodePacked(commitments[i].commitmentID)) == keccak256(abi.encodePacked(commitmentID)) &&
keccak256(abi.encodePacked(commitments[i].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
// Store the commitmentID before removing for the event
string memory foundCommitmentID = commitments[i].commitmentID;
string memory foundNodeId = commitments[i].nodeId;

// Shift the last element into the deleted slot to maintain array structure
commitments[i] = commitments[commitments.length - 1];
commitments.pop();

// Mark the commitmentID as unregistered
commitmentIDs[foundCommitmentID] = false;

// Emit the event for the removed Commitment
emit CommitmentRemoved(foundCommitmentID, foundNodeId, block.timestamp);
return;
}
}
revert("Commitment not found");
}

// Function to get the number of Commitment entries
function getCommitmentCount() public view returns (uint256) {
return commitments.length;
}
}
