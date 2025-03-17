// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import "@openzeppelin/contracts/access/Ownable.sol";


/*************************************************************
 * @title NodeManagers
 * @dev A smart contract to manage the node managers of different nodes in the network.
 *      - Allows the smart contract owner to add or remove node managers of nodes.
 *      - Ensures that only node managers can perform certain actions within the network.
 *      - Provides functionality to check if an address is a node manager and retrieve the nodeId associated with it.
 */
contract NodeManagers is Ownable {
    mapping(address => bool) private isManager; // Tracks whether an address is a node manager
    mapping(address => string) internal managerNodeId; // Maps each node manager's address to a specific nodeId
    address[] private managerList; // List of all node managers

    // Custom errors to revert transactions with detailed messages.
    error NodeManagers__IsNotManager(address account);
    error NodeManagers__IsAlreadyManager(address account);
    error NodeManagers__NodeIdMismatch(address account, string nodeId);

    // Events raised when a node manager is added or removed.
    event ManagerAdded(address indexed manager, string nodeId);
    event ManagerRemoved(address indexed manager);

    /**
     * @dev Constructor to initialize the smart contract with the smart contract owner who is the caller of this contract for the first time..
     *      - Inherits from Ownable to ensure only the smart contract owner can execute certain functions.
     * 
     * @param initialOwner is the address of the smart contract owner who called this contract for the first time.
     */
    constructor(address initialOwner) Ownable(initialOwner) {}

    /**
     * @dev Modifier to check that the sender is a registered node manager.
     *      - Reverts if the sender is not a node manager.
     */
    modifier onlyManager() {
        _checkManager(msg.sender);
        _;
    }

    /**
     * @dev Modifier to check that the sender is a node manager of the specific node.
     *      - Reverts if the sender is not the node manager of the specified node.
     * 
     * @param nodeId is the ID of the node to be checked.
     */
    modifier onlyManagerOfNode(string memory nodeId) {
        if (keccak256(abi.encodePacked(managerNodeId[msg.sender])) != keccak256(abi.encodePacked(nodeId))) {
            revert NodeManagers__NodeIdMismatch(msg.sender, nodeId);
        }
        _;
    }

    /**
     * @dev Internal function to check if an address is a registered node manager.
     *      - Reverts with an error if the address is not a node manager.
     * 
     * @param account is the address to be checked.
     */
    function _checkManager(address account) internal view {
        if (!isManager[account]) {
            revert NodeManagers__IsNotManager(account);
        }
    }

    /**
     * @dev Allows the smart contract owner to add a new node manager to the network.
     *      - Reverts if the address is already a node manager.
     *      - Assigns the provided nodeId to the node manager.
     * 
     * @param account is The address of the account to be added as a node manager.
     * @param nodeId is The ID of the node that the node manager will oversee.
     */
    function addManager(address account, string memory nodeId) external onlyOwner {
        if (isManager[account]) {
            revert NodeManagers__IsAlreadyManager(account);
        }
        isManager[account] = true;
        managerNodeId[account] = nodeId;
        managerList.push(account); // Add the address to the list of managers

        emit ManagerAdded(account, nodeId);
    }

    /**
     * @dev Allows the smart contract owner to remove a node manager from the network.
     *      - Reverts if the address is not a node manager.
     * 
     * @param account is The address of the node manager to be removed.
     */
    function removeManager(address account) external onlyOwner {
        if (!isManager[account]) {
            revert NodeManagers__IsNotManager(account);
        }
        delete isManager[account];
        delete managerNodeId[account];

        // Remove from the manager list
        for (uint i = 0; i < managerList.length; i++) {
            if (managerList[i] == account) {
                managerList[i] = managerList[managerList.length - 1];
                managerList.pop();
                break;
            }
        }

        emit ManagerRemoved(account);
    }

    /**
     * @dev Allows anyone to retrieve the nodeId associated with a specific node manager's address.
     *      - Ensures that the address is a registered node manager before fetching the nodeId.
     * 
     * @param account is The address of the node manager whose nodeId is to be fetched.
     * @return The nodeId associated with the manager.
     */
    function getManagerNodeId(address account) external view returns (string memory) {
        require(isManager[account], "Address is not a manager");
        return managerNodeId[account];
    }

    /**
     * @dev Function to retrieve the list of all node managers and their associated nodeIds.
     * @return A tuple containing two arrays: one with manager addresses and another with the corresponding nodeIds.
     */
    function getAllManagers() external view returns (address[] memory, string[] memory) {
        uint256 length = managerList.length;
        string[] memory nodeIds = new string[](length);

        // Retrieve the nodeId for each manager
        for (uint i = 0; i < length; i++) {
            nodeIds[i] = managerNodeId[managerList[i]];
        }

        return (managerList, nodeIds); // Return both addresses and nodeIds
    }
}


/*************************************************************
 * @title DeviceSharingManagement
 * @dev A smart contract for share/unshare accessing IoT devices.
 *      - Allows the node manager to create, remove, and fetch IoT devices.
 *      - Ensures that IoT devices have unique IDs within the node and prevents duplication.
 *      - Provides functionality to store IoT device details, such as type, model, manufacturer, parameters, ownership, etc.
 *      - Emits events to notify about IoT device creation and removal.
 */
contract DeviceSharingManagement is NodeManagers {
    
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
        string sharedDateTime;      // Timestamp when the device was shared
        string softwareVersion;       // Software/firmware version of the device (e.g., '1.0.0')
    }

    // Error handling for duplicated device IDs and non-existent devices
    error DeviceManagement__DuplicatedId(string nodeId, string deviceId);
    error DeviceManagement__DeviceIdNotExist(string nodeId, string deviceId);

    constructor(address initialOwner) NodeManagers(initialOwner) {}

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
     * @param sharedDateTime Timestamp when the device was shared
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
        string memory sharedDateTime,
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
            sharedDateTime,
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
     * @dev Fetches all devices associated with the caller's node.
     *      - Can only be executed by a registered manager.
     *      - Returns an array of device details for the caller's node.
     * 
     * @return Device[] An array of `Device` structs containing the details of all devices in the caller's node.
     */
    function fetchAllDevicesPerNode() external view onlyManager returns (Device[] memory) {
        string memory nodeId = managerNodeId[msg.sender];
        uint256 deviceCount = 0;

        // Count the number of devices in the caller's node
        for (uint256 i = 0; i < s_deviceIDs.length; i++) {
            if (keccak256(abi.encodePacked(s_devices[s_deviceIDs[i]].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
                deviceCount++;
            }
        }

        Device[] memory dataArray = new Device[](deviceCount);
        uint256 index = 0;

        // Collect devices belonging to the caller's node
        for (uint256 i = 0; i < s_deviceIDs.length; i++) {
            if (keccak256(abi.encodePacked(s_devices[s_deviceIDs[i]].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
                dataArray[index] = s_devices[s_deviceIDs[i]];
                index++;
            }
        }

        return dataArray;
    }

    /**
     * @dev Fetches all devices in the network.
     *      - Can only be executed by a registered manager.
     *      - Returns an array of all device details.
     * 
     * @return Device[] An array of `Device` structs containing the details of all devices.
     */
    function fetchAllDevices() external view onlyManager returns (Device[] memory) {
        Device[] memory dataArray = new Device[](s_deviceIDs.length);

        // Populate the array with all device details
        for (uint256 i = 0; i < s_deviceIDs.length; i++) {
            dataArray[i] = s_devices[s_deviceIDs[i]];
        }

        return dataArray;
    }

}


/*************************************************************
 * @title ServiceManagement
 * @dev This contract manages the creation, removal, and fetching of IoT services associated with specific nodes.
 * Each service has a unique ID within a node and contains metadata such as name, description, type, associated devices,
 * pricing information, image URL, and timestamps for creation and publication, etc.
 */
contract ServiceManagement is DeviceSharingManagement {
    /**
     * @dev Structure representing a service entity.
     * @param nodeId: Unique identifier of the node the service belongs to.
     * @param serviceId: Unique identifier for the service within the node.
     * @param name: Name of the service.
     * @param description: Brief description of the service.
     * @param serviceType: Type of the service (e.g., 'Automation', 'MachineLearning').
     * @param devices: List of associated device IDs.
     * @param installationPrice: Cost of installing the service.
     * @param executionPrice: Cost of executing the service.
     * @param imageUrl: URL linking to the service image.
     * @param program: Program code defining the service logic.
     * @param creationDate: Timestamp marking the service creation.
     * @param publishedDate: Timestamp marking when the service was published.
     */
    struct Service {
        string nodeId; // Unique identifier of the node the service belongs to
        string serviceId; // Unique identifier for the service within the node
        string name; // Name of the service
        string description;     // Brief description of the service
        string serviceType; // Type of the service (e.g., 'Automation', 'MachineLearning')
        string devices; // List of associated device IDs
        string installationPrice; // Cost of installing the service
        string executionPrice;  // Cost of executing the service
        string imageUrl; // URL linking to the service image
        string program; // Program code defining the service logic
        string creationDate; // Timestamp marking the service creation
        string publishedDate; // Timestamp marking when the service was published
    }

    /// @dev Error thrown when attempting to create a service with a duplicate service ID within the same node.
    error ServiceManagement__DuplicatedId(string nodeId, string serviceId);
    
    /// @dev Error thrown when trying to remove a service that does not exist.
    error ServiceManagement__ServiceIdNotExist(string nodeId, string serviceId);

    constructor(address initialOwner) DeviceSharingManagement(initialOwner) {}

    /// @dev Mapping of service database IDs to service structs.
    mapping(uint256 id => Service service) private s_services;
    
    /// @dev Mapping of node and service IDs to unique database IDs for quick lookups.
    mapping(string nodeId => mapping(string serviceId => uint256 id)) private s_serviceFindId;
    
    /// @dev Counter for assigning unique database IDs to services.
    uint256 private s_serviceDatabaseId = 1;
    
    /// @dev List of all service database IDs.
    uint256[] private s_serviceIDs;

    /// @dev Event emitted when a new service is created.
    event ServiceCreated(uint256 indexed id, Service service);
    
    /// @dev Event emitted when a service is removed.
    event ServiceRemoved(uint256 indexed id, Service service);

    /**
     * @notice Registers a new service for a given node.
     * @dev Ensures the service ID is unique within the node before storing service details.
     * Emits a `ServiceCreated` event upon success.
     * 
     * @param nodeId The unique identifier of the node to which the service belongs.
     * @param serviceId The unique identifier for the service within the node.
     * @param name The name of the service.
     * @param description A brief description of the service. 
     * @param serviceType The type of the service.
     * @param devices list of device IDs
     * @param installationPrice Cost of installing the service
     * @param executionPrice Cost of installing the service
     * @param imageUrl URL linking to the service image
     * @param program  Program code defining the service logic
     * @param creationDate Timestamp marking the service creation
     * @param publishedDate Timestamp marking when the service was published
     * @return uint256 The unique database ID assigned to the newly created service.
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
        string memory imageUrl,
        string memory program,
        string memory creationDate,
        string memory publishedDate
    ) external onlyManagerOfNode(nodeId) returns (uint256) {
        if (s_serviceFindId[nodeId][serviceId] != 0) {
            revert ServiceManagement__DuplicatedId(nodeId, serviceId);
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
            imageUrl,
            program,
            creationDate,
            publishedDate
        );
        s_serviceIDs.push(s_serviceDatabaseId);

        emit ServiceCreated(s_serviceDatabaseId, s_services[s_serviceDatabaseId]);
        return s_serviceDatabaseId++;
    }

    /**
     * @notice Removes an existing service from a node.
     * @dev Ensures that the service exists before removal.
     * Emits a `ServiceRemoved` event upon success.
     * 
     * @param targetNodeId: The node identifier from which the service should be removed.
     * @param targetServiceId: The service identifier to remove.
     * @param nodeId: The identifier of the node executing the function (must be the manager of this node).
     */
    function removeService(
        string memory targetNodeId,
        string memory targetServiceId,
        string memory nodeId
    ) external onlyManagerOfNode(nodeId) {
        if (s_serviceFindId[targetNodeId][targetServiceId] == 0) {
            revert ServiceManagement__ServiceIdNotExist(targetNodeId, targetServiceId);
        }

        uint256 targetId = s_serviceFindId[targetNodeId][targetServiceId];
        for (uint256 i; i < s_serviceIDs.length; i++) {
            if (s_serviceIDs[i] == targetId) {
                s_serviceIDs[i] = s_serviceIDs[s_serviceIDs.length - 1];
                s_serviceIDs.pop();
                break;
            }
        }

        s_serviceFindId[targetNodeId][targetServiceId] = 0;
        emit ServiceRemoved(targetId, s_services[targetId]);
        delete s_services[targetId];
    }

   /**
     * @dev Fetches all services in the network.
     *      - Can only be executed by a registered manager.
     *      - Returns an array of all service details.
     * 
     * @return Service[] An array of `Service` structs containing the details of all services.
     */
    function fetchAllServices() external view onlyManager returns (Service[] memory) {
        Service[] memory dataArray = new Service[](s_serviceIDs.length);

        // Populate the array with all service details
        for (uint256 i = 0; i < s_serviceIDs.length; i++) {
            dataArray[i] = s_services[s_serviceIDs[i]];
        }

        return dataArray;
    }

    /**
     * @dev Fetches all services associated with the caller's node.
     *      - Can only be executed by a registered manager.
     *      - Returns an array of service details for the caller's node.
     * 
     * @return Service[] An array of `Service` structs containing the details of all services in the caller's node.
     */
    function fetchAllServicesPerNode() external view onlyManager returns (Service[] memory) {
        string memory nodeId = managerNodeId[msg.sender];
        uint256 serviceCount = 0;

        // Count the number of services in the caller's node
        for (uint256 i = 0; i < s_serviceIDs.length; i++) {
            if (keccak256(abi.encodePacked(s_services[s_serviceIDs[i]].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
                serviceCount++;
            }
        }

        Service[] memory dataArray = new Service[](serviceCount);
        uint256 index = 0;

        // Collect services belonging to the caller's node
        for (uint256 i = 0; i < s_serviceIDs.length; i++) {
            if (keccak256(abi.encodePacked(s_services[s_serviceIDs[i]].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
                dataArray[index] = s_services[s_serviceIDs[i]];
                index++;
            }
        }

        return dataArray;
    }

}
      contract Protocol is ServiceManagement {
        constructor(address initialOwner) ServiceManagement(initialOwner) {}
}
