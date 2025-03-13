// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";



/**
 * @title AccessManagers
 * @dev A smart contract to manager the node managers of different nodes in the network.
 *      - Allows the smart contract owner to add or remove node managers of nodes.
 *      - Ensures that only node managers can perform certain actions within the network.
 *      - Provides functionality to check if an address is a node manager and retrieve the nodeId associated with it.
 */
contract AccessManagers is Ownable {
    mapping(address => bool) private isManager; // Tracks whether an address is a node manager
    mapping(address => string) private managerNodeId; // Maps each node manager's address to a specific nodeId

    // Custom errors to revert transactions with detailed messages.
    error AccessManagers__IsNotManager(address account);
    error AccessManagers__IsAlreadyManager(address account);
    error AccessManagers__NodeIdMismatch(address account, string nodeId);

    // Events raised when a node manager is added or removed.
    event ManagerAdded(address indexed manager, string nodeId);
    event ManagerRemoved(address indexed manager);

    /**
     * @dev Constructor to initialize the smart contract with the smart contract owner who is the caller of this contract for the first time..
     *      - Inherits from Ownable to ensure only the samrt contract owner can execute certain functions.
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
            revert AccessManagers__NodeIdMismatch(msg.sender, nodeId);
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
            revert AccessManagers__IsNotManager(account);
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
            revert AccessManagers__IsAlreadyManager(account);
        }
        isManager[account] = true;
        managerNodeId[account] = nodeId;

        emit ManagerAdded(account, nodeId);
    }

    /**
     * @dev Allows the smart contract owner to remove a node manager from the network.
     *      - Reverts if the address is not a node manager.
     * 
     * @param account is The address of the nodemanager to be removed.
     */
    function removeManager(address account) external onlyOwner {
        if (!isManager[account]) {
            revert AccessManagers__IsNotManager(account);
        }
        delete isManager[account];
        delete managerNodeId[account];

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
}




/**
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
     * @param nodeId: The unique identifier of the node to which the device will be registered.
     * @param deviceId: The unique identifier of the device (e.g., MAC address, VIN).
     * @param deviceType: The type of the device (e.g., "Car", "Sensor").
     * @param deviceIdType: The type of the device ID (e.g., "MAC", "VIN").
     * @param deviceModel: The model of the device (e.g., "zkMultiSensor", "ECard").
     * @param manufacturer: The manufacturer of the device (e.g., "Simense", "Tesla").
     * @param parameters: The device parameters (e.g., ["temperature", "humidity"]).
     * @param useCost: The cost of using the device (e.g., "23").
     * @param deviceCoordination: The GPS coordinates of the device (e.g., [23.4, 45.6]).
     * @param ownernershipId: The digital ownership ID of the device (e.g., wallet address).
     * @param sharedTimestamp: The timestamp indicating when the device was shared.
     * @param softwareVersion: The software/firmware version of the device (e.g., "1.0.0").
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




/**
 * @title ServiceManagement
 * @dev This contract manages the creation, removal, and Fetching of IoT services associated with specific nodes.
 * Each service has a unique ID within a node and contains metadata such as name, description, type, associated devices,
 * pricing information, image URL, and timestamps for creation and publication, etc.
 */
contract ServiceManagement is DeviceManagement {
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
        string nodeId;
        string serviceId;
        string name;
        string description;
        string serviceType;
        string devices;
        string installationPrice;
        string executionPrice;
        string imageUrl;
        string program;
        string creationDate;
        string publishedDate;
    }

    /// @dev Error thrown when attempting to create a service with a duplicate service ID within the same node.
    error ServiceManagement__DuplicatedId(string nodeId, string serviceId);
    
    /// @dev Error thrown when trying to remove a service that does not exist.
    error ServiceManagement__ServiceIdNotExist(string nodeId, string serviceId);

    constructor(address initialOwner) DeviceManagement(initialOwner) {}

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
     * @param nodeId: Unique identifier of the node.
     * @param serviceId: Unique identifier for the service within the node.
     * @param name: Name of the service.
     * @param description: Description of the service.
     * @param serviceType: Type of the service (e.g., 'Automation', 'MachineLearning').
     * @param devices: List of associated device IDs.
     * @param installationPrice: Cost of installing the service.
     * @param executionPrice: Cost of executing the service.
     * @param imageUrl: URL linking to the service image.
     * @param program: Program code defining the service logic.
     * @param creationDate: Timestamp marking the service creation.
     * @param publishedDate: Timestamp marking when the service was published.
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
     * @notice Retrieves all services associated with a given node.
     * @dev Can only be executed by the manager of the node.
     * 
     * @param nodeId: The unique identifier of the node.
     * @return Service[] An array containing details of all services within the specified node.
     */
    function fetchAllServices(
        string memory nodeId
    ) external view onlyManagerOfNode(nodeId) returns (Service[] memory) {
        Service[] memory dataArray = new Service[](s_serviceIDs.length);
        for (uint256 i = 0; i < s_serviceIDs.length; i++) {
            dataArray[i] = s_services[s_serviceIDs[i]];
        }
        return dataArray;
    }
}



/**
 * @title CommitmentStorage
 * @dev This contract allows storing, retrieving, and removing commitments for IoT devices.
 * Commitments contain various metadata including device details, commitment data, timestamps, etc.
 */
contract CommitmentStorage {
    /**
     * @dev Struct to store commitment details.
     * @param commitmentId:Unique identifier for the commitment.
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
     * @param commitmentId: Unique identifier for the commitment.
     * @param nodeId: Node ID where the commitment is registered.
     * @param deviceType: Type of the IoT device.
     * @param deviceIdType: Type of the device identifier.
     * @param deviceModel: Model of the IoT device.
     * @param manufacturer: Manufacturer name of the IoT device.
     * @param softwareVersion: Software or firmware version.
     * @param commitment: The commitment data.
     * @param timestamp: Timestamp of the commitment.
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
        require(!commitmentIds[commitmentId], "commitmentId already registered");

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
     * @notice Retrieve all stored commitments. (Function implementation is required)
     * @dev This function should return an array contains all the commitments.
     */
    function getAllCommitmentsData() public view returns (Commitment[] memory) {
        return commitments;
    }
}




/**
 * @title ZKPStorage
 * @dev A smart contract for storing and retrieving Zero-Knowledge Proof (ZKP) data related to IoT devices.
 */
contract ZKPStorage {

     /**
     * @dev Emitted when a new commitment is stored.
     * @param commitmentID The unique identifier for the commitment.
     * @param nodeId The ID of the node associated with the commitment.
     * @param deviceType The type of the IoT device (e.g., sensor, actuator).
     * @param deviceIdType The type of the device ID (e.g., 'MAC', 'VIN').
     * @param deviceModel The model of the IoT device.
     * @param manufacturer The name of the manufacturer of the IoT device.
     * @param softwareVersion The software or firmware version of the IoT device.
     * @param commitment The commitment data, as described in the commitment file on the project GitHub.
     * @param timestamp The timestamp when the commitment was stored.
     */


    struct ZKP {

    string commitmentID,
    string nodeId,
    string deviceType,
    string deviceIdType,
    string deviceModel,
    string manufacturer,
    string softwareVersion,
    string commitment,
    uint256 timestamp

    }

    ZKP[] public zkps;

    /**
     * @dev Emitted when a new ZKP is stored.
     * @param nodeId: The unique identifier of the node.
     * @param deviceId: The unique identifier of the IoT device.
     * @param deviceType: The type of the IoT device.
     * @param deviceIdType: The type of the device ID.
     * @param deviceModel: The model of the IoT device.
     * @param manufacturer: The manufacturer of the IoT device.
     * @param softwareVersion: The software/firmware version of the IoT device.
     * @param zkpPayload: The ZKP data associated with the IoT device.
     * @param dataPayload: The IoT device's data.
     * @param unixtimePayload: The Unix timestamp associated with the device data.
     * @param timestamp: The timestamp when the ZKP entry was created.
     */
    event ZKPStored(
    string commitmentID,
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
     * @dev Stores the ZKP data for an IoT device.
     * @param nodeId: The unique identifier of the node associated with the IoT device.
     * @param deviceId: The unique identifier of the IoT device.
     * @param deviceType: The type of the IoT device.
     * @param deviceIdType: The type of the device ID.
     * @param deviceModel: The model of the IoT device.
     * @param manufacturer: The manufacturer of the IoT device.
     * @param softwareVersion: The software/firmware version of the IoT device.
     * @param zkpPayload: The Zero-Knowledge Proof data associated with the IoT device.
     * @param dataPayload: The IoT device's data.
     * @param unixtimePayload: The Unix timestamp associated with the device data.
     * @param timestamp: The timestamp when the ZKP entry was created.
     */
    function storeZKP(
    string memory commitmentID,
    string memory nodeId,
    string memory deviceType,
    string memory deviceIdType,
    string memory deviceModel,
    string memory manufacturer,
    string memory softwareVersion,
    string memory commitment,
    uint256 timestamp
    ) public {
        zkps.push(ZKP({
    commitmentID: commitmentID,  
    nodeId: nodeId,  
    deviceType: deviceType,  
    deviceIdType: deviceIdType,  
    deviceModel: deviceModel,  
    manufacturer: manufacturer,  
    softwareVersion: softwareVersion,  
    commitment: commitment,  
    timestamp: timestamp
        }));

        emit ZKPStored(
    commitmentID,  
    nodeId,  
    deviceType,  
    deviceIdType,  
    deviceModel,  
    manufacturer,  
    softwareVersion,  
    commitment,  
    timestamp
        );
    }

    /**
     * @dev Retrieves the total number of ZKP entries stored.
     * @return The total number of ZKP entries stored in the contract.
     */
    function getZKPCount() public view returns (uint256) {
        return zkps.length;
    }

    /**
     * @dev Retrieves the ZKP data for an IoT device based on the provided index.
     * @param index The index of the ZKP data entry in the array to retrieve.
     * @return nodeId The unique identifier of the node.
     * @return deviceId The unique identifier of the IoT device.
     * @return deviceType The type of the IoT device.
     * @return deviceIdType The type of the device ID.
     * @return deviceModel The model of the IoT device.
     * @return manufacturer The manufacturer of the IoT device.
     * @return softwareVersion The software/firmware version of the IoT device.
     * @return zkpPayload The Zero-Knowledge Proof data associated with the IoT device.
     * @return dataPayload The IoT device's data.
     * @return unixtimePayload The Unix timestamp associated with the device data.
     * @return timestamp The timestamp when the ZKP entry was created.
     */
    function getZKP(uint256 index) public view returns (
    string memory commitmentID,
    string memory nodeId,
    string memory deviceType,
    string memory deviceIdType,
    string memory deviceModel,
    string memory manufacturer,
    string memory softwareVersion,
    string memory commitment,
    uint256 timestamp
    ) {
        require(index < zkps.length, "Index out of bounds");

        ZKP storage zkp = zkps[index];
        return (
          zkp.commitmentID,  
          zkp.nodeId,  
          zkp.deviceType,  
          zkp.deviceIdType,  
          zkp.deviceModel,  
          zkp.manufacturer,  
          zkp.softwareVersion,  
          zkp.commitment,  
          zkp.timestamp
        );
    }
}



/**
 * @title SignIdentity
 * @dev A smart contract for registering and managing identities with ownership binding.
 *      - A user can register an identity associated with a unique node ID.
 *      - Ownership can be assigned to a registered identity.
 *      - The identity and ownership can be bound together once both are registered.
 */

contract SignIdentity {
    struct Identity {
        address identityAddress;  // Identity address
        address ownershipAddress; // Ownership address
        uint256 nodeId;           // Node ID associated with the identity
        bool binding;             // Binding flag, false by default
    }

    mapping(address => Identity) public identities; // Stores identities with identity address as key
    mapping(uint256 => bool) public nodeExists;    // Tracks registered node IDs to prevent duplicates

    event IdentityRegistered(address indexed identityAddress, uint256 nodeId);
    event OwnershipRegistered(address indexed identityAddress, address indexed ownershipAddress);
    event IdentityBound(address indexed identityAddress, address indexed ownershipAddress);

    /**
     * @dev Registers a new identity if it does not already exist.
     * @param _nodeId The node ID associated with this identity.
     */
    function registerIdentity(uint256 _nodeId) public {
        require(identities[msg.sender].identityAddress == address(0), "Identity already registered");
        require(!nodeExists[_nodeId], "Node ID already registered");

        identities[msg.sender] = Identity({
            identityAddress: msg.sender,
            ownershipAddress: address(0),
            nodeId: _nodeId,
            binding: false
        });

        nodeExists[_nodeId] = true;

        emit IdentityRegistered(msg.sender, _nodeId);
    }

    /**
     * @dev Registers an ownership address for an existing identity.
     * @param _identityAddress The identity address for which ownership is being assigned.
     */
    function registerOwnership(address _identityAddress) public {
        require(identities[_identityAddress].identityAddress != address(0), "Identity does not exist");
        require(identities[_identityAddress].ownershipAddress == address(0), "Ownership already registered");

        identities[_identityAddress].ownershipAddress = msg.sender;

        emit OwnershipRegistered(_identityAddress, msg.sender);
    }

    /**
     * @dev Binds identity and ownership if both addresses match the stored identity.
     * @param _ownershipAddress The ownership address to bind with the identity.
     */
    function bindIdentityOwnership(address _ownershipAddress) public {
        Identity storage identity = identities[msg.sender];

        require(identity.identityAddress != address(0), "Identity does not exist");
        require(identity.ownershipAddress == _ownershipAddress, "Ownership address mismatch");
        require(!identity.binding, "Already bound");

        identity.binding = true;

        emit IdentityBound(msg.sender, _ownershipAddress);
    }
}


/**
 * @title DeviceNFT
 * @dev A smart contract to create and transfer NFTs representing IoT devices.
 *      - Ensures that each device (defined by deviceId, deviceIdType, deviceType, manufacturer, and deviceModel) is unique.
 *      - Provides functionality to transfer ownership of the NFT.
 */
contract DeviceNFT {
    struct Device {
        string deviceId;        // Unique identifier for the device
        string deviceIdType;    // Type of the device ID (e.g., 'MAC', 'VIN')
        string deviceType;      // Type of the IoT device (e.g., 'Sensor', 'Actuator')
        string manufacturer;    // Manufacturer of the device
        string deviceModel;     // Model of the device
        address ownershipAddress; // Address of the current owner
    }

    mapping(uint256 => Device) public devices;  // Mapping of NFT ID to Device details
    mapping(bytes32 => bool) public deviceExists; // Tracks existing devices to prevent duplicates
    uint256 public nextNFTId; // Counter for NFT IDs

    event NFTCreated(uint256 indexed nftId, address indexed ownershipAddress);
    event NFTTransferred(uint256 indexed nftId, address indexed from, address indexed to);

    /**
     * @dev Creates an NFT for an IoT device.
     *      - Ensures the device is unique before creating it.
     *      - Assigns ownership to the specified address.
     * 
     * @param ownershipAddress The address of the initial owner of the NFT.
     * @param deviceId The unique identifier of the device.
     * @param deviceIdType The type of the device ID (e.g., 'MAC', 'VIN').
     * @param deviceType The type of the IoT device (e.g., 'Sensor', 'Actuator').
     * @param manufacturer The manufacturer of the IoT device.
     * @param deviceModel The model of the IoT device.
     */
    function createNFT(
        address ownershipAddress,
        string memory deviceId,
        string memory deviceIdType,
        string memory deviceType,
        string memory manufacturer,
        string memory deviceModel
    ) public {
        bytes32 deviceHash = keccak256(abi.encode(deviceId, deviceIdType, deviceType, manufacturer, deviceModel));
        require(!deviceExists[deviceHash], "Device already exists");

        devices[nextNFTId] = Device({
            deviceId: deviceId,
            deviceIdType: deviceIdType,
            deviceType: deviceType,
            manufacturer: manufacturer,
            deviceModel: deviceModel,
            ownershipAddress: ownershipAddress
        });

        deviceExists[deviceHash] = true;

        emit NFTCreated(nextNFTId, ownershipAddress);
        nextNFTId++;
    }

    /**
     * @dev Transfers ownership of an existing NFT.
     *      - Ensures the sender is the current owner.
     *      - Updates the ownership address.
     * 
     * @param nftId The ID of the NFT being transferred.
     * @param receiverOwnershipAddress The address of the new owner.
     */
    function transferNFT(uint256 nftId, address receiverOwnershipAddress) public {
        require(nftId < nextNFTId, "NFT does not exist");
        require(msg.sender == devices[nftId].ownershipAddress, "Only the owner can transfer this NFT");
        require(receiverOwnershipAddress != address(0), "Invalid new owner address");

        address previousOwner = devices[nftId].ownershipAddress;
        devices[nftId].ownershipAddress = receiverOwnershipAddress;

        emit NFTTransferred(nftId, previousOwner, receiverOwnershipAddress);
    }
}



//
// the main contract which inherits from the other contracts.
//
contract Protocol is ServiceManagement, CommitmentStorage, ZKPStorage {
    constructor(address initialOwner)
        ServiceManagement(initialOwner)
        CommitmentStorage( )
        ZKPStorage( )
    {}
}