// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;



/*************************************************************
 * @title DeviceManagement
 * @dev A smart contract for managing IoT devices within a node.
 *      - Allows the node manager to create, remove, and fetch IoT devices.
 *      - Ensures that IoT devices have unique IDs within the node and prevents duplication.
 *      - Provides functionality to store IoT device details, such as type, model, manufacturer, parameters, ownership, etc.
 *      - Emits events to notify about IoT device creation and removal.
 */
contract DeviceManagement is AccessManagers {
    
    struct Device {
        string nodeId;                // Unique ID for the node to which the device is registered
        string deviceId;              // Unique ID for the device (e.g., MAC address, VIN number)
        string deviceType;            // Type of the device (e.g., Car, Sensor)
        string deviceIdType;          // Type of the device ID (e.g., 'MAC', 'VIN')
        string deviceModel;           // Model of the device (e.g., 'zkMultiSensor', 'ECard')
        string manufacturer;          // Manufacturer of the device (e.g., 'Simense', 'Tesla')
        string[] parameters;          // Parameters of the device (e.g., ['temperature', 'humidity'])
        string useCost;               // Cost of using the device (e.g., '23') FDS token
        string[] deviceCoordination;  // GPS coordinates of the device (e.g., [23.4, 45.6])
        string ownernershipId;        // Digital ownership ID of the device (e.g., wallet address)
        uint256 sharedTimestamp;      // Timestamp when the device was shared
        string softwareVersion;       // Software/firmware version of the device (e.g., '1.0.0')
    }

    // Error handling for duplicated device IDs and non-existent devices
    error DeviceManagement__DuplicatedId(string nodeId, string deviceId);
    error DeviceManagement__DeviceIdNotExist(string nodeId, string deviceId);

    constructor(address initialOwner) AccessManagers(initialOwner) {}

    mapping(uint256 => Device) private s_devices;          // Mapping of device IDs to device details
    mapping(string => mapping(string => uint256)) s_deviceFindId; // Mapping to find device by nodeId and device ID
    uint256 s_deviceDatabaseId = 1;                         // Counter for the number of device IDs inside the database
    uint256[] private s_deviceIDs;                          // Array to store device IDs

    // Events for device creation and removal
    event DeviceCreated(uint256 indexed id, Device device);
    event DeviceRemoved(uint256 indexed id, Device device);

    /**
     * @dev Creates a new IoT device and registers it within a specific node.
     *      - Ensures that the device ID is unique within the node.
     *      - Stores the device’s details, including ID, type, model, manufacturer, parameters, cost, etc.
     *      - Emits a `DeviceCreated` event.
     * 
     * @param nodeId Unique ID for the node to which the device is registered
     * @param deviceId Unique ID for the device (e.g., MAC address, VIN number)
     * @param deviceType Type of the device (e.g., Car, Sensor)
     * @param deviceIdType Type of the device ID (e.g., 'MAC', 'VIN')
     * @param deviceModel Model of the device (e.g., 'zkMultiSensor', 'ECard')
     * @param manufacturer Manufacturer of the device (e.g., 'Simense', 'Tesla')
     * @param parameters Parameters of the device (e.g., ['temperature', 'humidity'])
     * @param useCost Cost of using the device (e.g., '23') FDS token
     * @param deviceCoordination GPS coordinates of the device (e.g., [23.4, 45.6])
     * @param ownernershipId Digital ownership ID of the device (e.g., wallet address)
     * @param sharedTimestamp Timestamp when the device was shared
     * @param softwareVersion Software/firmware version of the device (e.g., '1.0.0')
     * 
     * @return uint256 The unique database ID assigned to the newly created device.
     */
    function createDevice(
        string memory nodeId,
        string memory deviceId,
        string memory deviceType,
        string memory deviceIdType,
        string memory deviceModel,
        string memory manufacturer,
        string[] memory parameters,
        string memory useCost,
        string[] memory deviceCoordination,
        string memory ownernershipId,
        uint256 sharedTimestamp,
        string memory softwareVersion
    ) external onlyManagerOfNode(nodeId) returns (uint256) {
        // Ensure the device ID is unique for the node
        if (s_deviceFindId[nodeId][deviceId] != 0) {
            revert DeviceManagement__DuplicatedId(nodeId, deviceId);
        }

        // Register the IoT device
        s_deviceFindId[nodeId][deviceId] = s_deviceDatabaseId;
        s_devices[s_deviceDatabaseId] = Device(
            nodeId,
            deviceId,
            deviceType,
            deviceIdType,
            deviceModel,
            manufacturer,
            parameters,
            useCost,
            deviceCoordination,
            ownernershipId,
            sharedTimestamp,
            softwareVersion
        );

        // Add the device ID to the list and emit the event
        s_deviceIDs.push(s_deviceDatabaseId);
        emit DeviceCreated(s_deviceDatabaseId, s_devices[s_deviceDatabaseId]);

        // Increase the database ID for the next device
        s_deviceDatabaseId++;
        return s_deviceDatabaseId;
    }

    /**
     * @dev Removes a device from a node's device list.
     *      - Ensures the device exists before attempting removal.
     *      - Emits a `DeviceRemoved` event to confirm the removal.
     * 
     * @param targetNodeId: The node ID from which the device will be removed.
     * @param targetDeviceId: The device ID to be removed.
     * @param nodeId: The node ID executing the function (must be the node manager).
     */
    function removeDevice(
        string memory targetNodeId,
        string memory targetDeviceId,
        string memory nodeId
    ) external onlyManagerOfNode(nodeId) {

        // Ensure the device exists
        if (s_deviceFindId[targetNodeId][targetDeviceId] == 0) {
            revert DeviceManagement__DeviceIdNotExist(targetNodeId, targetDeviceId);
        }

        uint256 targetId = s_deviceFindId[targetNodeId][targetDeviceId];
        uint256[] memory tempIDs = s_deviceIDs;

        // Remove the device ID from the list
        for (uint256 i; i < tempIDs.length; i++) {
            if (tempIDs[i] == targetId) {
                s_deviceIDs[i] = s_deviceIDs[s_deviceIDs.length - 1];
                s_deviceIDs.pop();
                break;
            }
        }

        // Remove the device from the mapping and emit the event
        s_deviceFindId[targetNodeId][targetDeviceId] = 0;
        emit DeviceRemoved(targetId, s_devices[targetId]);

        // Delete the device
        delete (s_devices[targetId]);
    }

    /**
     * @dev Fetches all devices associated with a specific node.
     *      - Can only be executed by the node manager.
     *      - Returns an array of device details.
     * 
     * @param nodeId: The unique identifier of the node for which the device details are to be fetched.
     * 
     * @return Device[] An array of `Device` structs containing the details of all devices in the node.
     */
    function fetchAllDevices(
        string memory nodeId
    ) external view onlyManagerOfNode(nodeId) returns (Device[] memory) {
        Device[] memory dataArray = new Device[](s_deviceIDs.length);

        // Populate the array with device details
        for (uint256 i = 0; i < s_deviceIDs.length; i++) {
            dataArray[i] = s_devices[s_deviceIDs[i]];
        }

        return dataArray;
    }
}