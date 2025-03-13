// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


/*************************************************************
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

