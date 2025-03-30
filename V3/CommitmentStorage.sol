// SPDX-License-Identifier: MIT
pragma solidity 0.8.29;



/*************************************************************
 * @title CommitmentStorage
 * @dev This contract allows storing, retrieving, and removing commitments on the blockchain.
 * Commitments contain various metadata including device details, commitment data, timestamps, etc.
 */
contract CommitmentStorage {
    /**
     * @dev Struct to store commitment details.
     * @param commitmentId: Unique identifier for the commitment.
     * @param nodeId: Unique identifier of the node where the commitment is registered.
     * @param deviceType: Type of the IoT device (e.g., 'Sensor', 'Actuator').
     * @param deviceIdType: Type of the device identifier (e.g., 'MAC', 'VIN').
     * @param deviceModel: Model of the IoT device.
     * @param manufacturer: Manufacturer of the IoT device.
     * @param softwareVersion: Software or firmware version of the device.
     * @param commitment: Actual commitment data adhering to a certain specification.
     * @param timestamp: Timestamp when the commitment was stored.
     */
    struct Commitment {
        string commitmentId;
        string nodeId;
        string deviceType;
        string deviceIdType;
        string deviceModel;
        string manufacturer;
        string softwareVersion;
        string commitment;
        uint256 timestamp;
    }

    // Array to store commitments
    Commitment[] public commitments;

    // Mapping to check if a commitment ID already exists
    mapping(string => bool) public commitmentIds;

    /**
     * @dev Event emitted when a commitment is successfully stored.
     */
    event CommitmentStored(
        string commitmentId,
        string nodeId,
        string deviceType,
        string deviceIdType,
        string deviceModel,
        string manufacturer,
        string softwareVersion,
        string commitment,
        uint256 timestamp
    );

    /**
     * @dev Event emitted when a commitment is successfully removed.
     */
    event CommitmentRemoved(string commitmentId, string nodeId, uint256 timestamp);

    /**
     * @notice Store a commitment for an IoT device.
     * @param commitmentId  Unique identifier for the commitment. 
     * @param nodeId Unique identifier of the node where the commitment is registered.
     * @param deviceType Type of the IoT device (e.g., 'Sensor', 'Actuator').
     * @param deviceIdType Type of the device identifier (e.g., 'MAC', 'VIN').
     * @param deviceModel Model of the IoT device.
     * @param manufacturer Manufacturer of the IoT device.
     * @param softwareVersion Software or firmware version of the device.
     * @param commitment Actual commitment data adhering to a certain specification.
     * @param timestamp Timestamp when the commitment was stored.
     * @return bool Returns true if the commitment was successfully stored.
     */
    function storeCommitment(
        string memory commitmentId,
        string memory nodeId,
        string memory deviceType,
        string memory deviceIdType,
        string memory deviceModel,
        string memory manufacturer,
        string memory softwareVersion,
        string memory commitment,
        uint256 timestamp
    ) public returns (bool) {
        require(!commitmentIds[commitmentId], "commitmentId already registered.");

        commitments.push(Commitment({
            commitmentId: commitmentId,
            nodeId: nodeId,
            deviceType: deviceType,
            deviceIdType: deviceIdType,
            deviceModel: deviceModel,
            manufacturer: manufacturer,
            softwareVersion: softwareVersion,
            commitment: commitment,
            timestamp: block.timestamp
        }));

        commitmentIds[commitmentId] = true;

        emit CommitmentStored(
            commitmentId, nodeId, deviceType, deviceIdType, 
            deviceModel, manufacturer, softwareVersion, commitment, timestamp
        );
        return true;
    }

    /**
     * @notice Retrieve commitment data based on the commitment ID and node ID.
     * @param commitmentId: Unique identifier of the commitment.
     * @param nodeId: Node ID where the commitment is registered.
     * @return All stored details of the commitment.
     */
    function getCommitment(
        string memory commitmentId, 
        string memory nodeId
    ) public view returns (
        string memory, string memory, string memory, string memory, string memory, 
        string memory, string memory, string memory, uint256
    ) {
        for (uint256 i = 0; i < commitments.length; i++) {
            if (
                keccak256(abi.encodePacked(commitments[i].commitmentId)) == keccak256(abi.encodePacked(commitmentId)) &&
                keccak256(abi.encodePacked(commitments[i].nodeId)) == keccak256(abi.encodePacked(nodeId))
            ) {
                Commitment storage commitment = commitments[i];
                return (
                    commitment.commitmentId, commitment.nodeId, commitment.deviceType, 
                    commitment.deviceIdType, commitment.deviceModel, commitment.manufacturer, 
                    commitment.softwareVersion, commitment.commitment, commitment.timestamp
                );
            }
        }
        revert("Commitment not found");
    }

    /**
     * @notice Remove a commitment based on the commitment ID and node ID.
     * @param commitmentId: Unique identifier of the commitment to remove.
     * @param nodeId: Node ID associated with the commitment.
     */
    function removeCommitment(string memory commitmentId, string memory nodeId) public {
        for (uint256 i = 0; i < commitments.length; i++) {
            if (
                keccak256(abi.encodePacked(commitments[i].commitmentId)) == keccak256(abi.encodePacked(commitmentId)) &&
                keccak256(abi.encodePacked(commitments[i].nodeId)) == keccak256(abi.encodePacked(nodeId))
            ) {
                commitments[i] = commitments[commitments.length - 1];
                commitments.pop();
                commitmentIds[commitmentId] = false;
                emit CommitmentRemoved(commitmentId, nodeId, block.timestamp);
                return;
            }
        }
        revert("Commitment not found");
    }

    /**
     * @notice Get the total number of commitments stored.
     * @return uint256 The total number of commitments.
     */
    function getCommitmentCount() public view returns (uint256) {
        return commitments.length;
    }

    /**
     * @notice Retrieve all stored commitments.
     * @dev This function should return an array contains all the commitments.
     */
    function getAllCommitmentsData() public view returns (Commitment[] memory) {
        return commitments;
    }
}
