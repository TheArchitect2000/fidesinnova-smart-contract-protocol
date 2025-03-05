// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Context.sol";
//import "./AccessManagers.sol"; // 

//  AccessManagers.sol


contract AccessManagers is Ownable {
    mapping(address => bool) private isManager;
    mapping(address => string) private managerNodeId; // Maintain nodeId of each manager

    error AccessManagers__IsNotManager(address account);
    error AccessManagers__IsAlreadyManager(address account);
    error AccessManagers__NodeIdMismatch(address account, string nodeId);

    event ManagerAdded(address indexed manager, string nodeId);
    event ManagerRemoved(address indexed manager);

    constructor(address initialOwner) Ownable(initialOwner) {}

    modifier onlyManager() {
        _checkManager(msg.sender);
        _;
    }

    modifier onlyManagerOfNode(string memory nodeId) {
        if (keccak256(abi.encodePacked(managerNodeId[msg.sender])) != keccak256(abi.encodePacked(nodeId))) {
            revert AccessManagers__NodeIdMismatch(msg.sender, nodeId);
        }
        _;
    }

    function _checkManager(address account) internal view {
        if (!isManager[account]) {
            revert AccessManagers__IsNotManager(account);
        }
    }

    function addManager(address account, string memory nodeId) external onlyOwner {
        if (isManager[account]) {
            revert AccessManagers__IsAlreadyManager(account);
        }
        isManager[account] = true;
        managerNodeId[account] = nodeId;

        emit ManagerAdded(account, nodeId);
    }

    function removeManager(address account) external onlyOwner {
        if (!isManager[account]) {
            revert AccessManagers__IsNotManager(account);
        }
        delete isManager[account];
        delete managerNodeId[account];

        emit ManagerRemoved(account);
    }

    function getManagerNodeId(address account) external view returns (string memory) {
        require(isManager[account], "Address is not a manager");
        return managerNodeId[account];
    }
}

//  DeviceManagement.sol
contract DeviceManagement is AccessManagers {
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

    error DeviceManagement__DuplicatedId(string nodeId, string deviceId);
    error DeviceManagement__DeviceIdNotExist(string nodeId, string deviceId);

    constructor(address initialOwner) AccessManagers(initialOwner) {}

    mapping(uint256 id => Device device) private s_devices;
    mapping(string nodeId => mapping(string deviceId => uint256 id)) s_deviceFindId;
    uint256 s_deviceDatabaseId = 1;
    uint256[] private s_deviceIDs;

    event DeviceCreated(uint256 indexed id, Device device);
    event DeviceRemoved(uint256 indexed id, Device device);

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
    ) external onlyManagerOfNode(nodeId) returns (uint256) {
        if (s_deviceFindId[nodeId][deviceId] != 0) {
            revert DeviceManagement__DuplicatedId(nodeId, deviceId);
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

    function removeDevice(
        string memory targetNodeId,
        string memory targetDeviceId,
        string memory nodeId
    ) external onlyManagerOfNode(nodeId) {
        if (s_deviceFindId[targetNodeId][targetDeviceId] == 0) {
            revert DeviceManagement__DeviceIdNotExist(targetNodeId, targetDeviceId);
        }

        uint256 targetId = s_deviceFindId[targetNodeId][targetDeviceId];
        uint256[] memory tempIDs = s_deviceIDs;
        for (uint256 i; i < tempIDs.length; i++) {
            if (tempIDs[i] == targetId) {
                s_deviceIDs[i] = s_deviceIDs[s_deviceIDs.length - 1];
                s_deviceIDs.pop();
                break;
            }
        }

        s_deviceFindId[targetNodeId][targetDeviceId] = 0;

        emit DeviceRemoved(targetId, s_devices[targetId]);

        delete (s_devices[targetId]);
    }

    function fetchAllDevices(
        string memory nodeId
    ) external view onlyManagerOfNode(nodeId) returns (Device[] memory) {
        Device[] memory dataArray = new Device[](s_deviceIDs.length);
        for (uint256 i = 0; i < s_deviceIDs.length; i++) {
            dataArray[i] = s_devices[s_deviceIDs[i]];
        }
        return dataArray;
    }
}

//  ServiceManagement.sol
contract ServiceManagement is DeviceManagement {
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

    error ServiceManagement__DuplicatedId(string nodeId, string serviceId);
    error ServiceManagement__ServiceIdNotExist(string nodeId, string serviceId);

    constructor(address initialOwner) DeviceManagement(initialOwner) {}

    mapping(uint256 id => Service service) private s_services;
    mapping(string nodeId => mapping(string serviceId => uint256 id)) s_serviceFindId;
    uint256 s_serviceDatabaseId = 1;
    uint256[] private s_serviceIDs;

    event ServiceCreated(uint256 indexed id, Service service);
    event ServiceRemoved(uint256 indexed id, Service service);

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
            imageURL,
            program,
            creationDate,
            publishedDate
        );
        s_serviceIDs.push(s_serviceDatabaseId);

        emit ServiceCreated(s_serviceDatabaseId, s_services[s_serviceDatabaseId]);
        s_serviceDatabaseId++;
        return s_serviceDatabaseId;
    }

    function removeService(
        string memory targetNodeId,
        string memory targetServiceId,
        string memory nodeId
    ) external onlyManagerOfNode(nodeId) {
        if (s_serviceFindId[targetNodeId][targetServiceId] == 0) {
            revert ServiceManagement__ServiceIdNotExist(targetNodeId, targetServiceId);
        }

        uint256 targetId = s_serviceFindId[targetNodeId][targetServiceId];
        uint256[] memory tempIDs = s_serviceIDs;
        for (uint256 i; i < tempIDs.length; i++) {
            if (tempIDs[i] == targetId) {
                s_serviceIDs[i] = s_serviceIDs[s_serviceIDs.length - 1];
                s_serviceIDs.pop();
                break;
            }
        }

        s_serviceFindId[targetNodeId][targetServiceId] = 0;

        emit ServiceRemoved(targetId, s_services[targetId]);

        delete (s_services[targetId]);
    }

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

//  CommitmentStorage.sol
contract CommitmentStorage {
    struct Commitment {
        string commitmentID;
        string nodeId;
        string iot_manufacturer_name;
        string iot_device_name;
        string device_hardware_version;
        string firmware_version;
        string commitmentData;
        uint256 timestamp;
    }

    Commitment[] public commitments;
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

    function storeCommitment(
        string memory commitmentID,
        string memory nodeId,
        string memory iot_manufacturer_name,
        string memory iot_device_name,
        string memory device_hardware_version,
        string memory firmware_version,
        string memory commitmentData
    ) public returns (bool) {
        if (commitmentIDs[commitmentID]) {
            revert("CommitmentID already registered");
        }

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

        commitmentIDs[commitmentID] = true;

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

    function removeCommitment(string memory commitmentID, string memory nodeId) public {
        for (uint256 i = 0; i < commitments.length; i++) {
            if (keccak256(abi.encodePacked(commitments[i].commitmentID)) == keccak256(abi.encodePacked(commitmentID)) &&
                keccak256(abi.encodePacked(commitments[i].nodeId)) == keccak256(abi.encodePacked(nodeId))) {
                string memory foundCommitmentID = commitments[i].commitmentID;
                string memory foundNodeId = commitments[i].nodeId;

                commitments[i] = commitments[commitments.length - 1];
                commitments.pop();

                commitmentIDs[foundCommitmentID] = false;

                emit CommitmentRemoved(foundCommitmentID, foundNodeId, block.timestamp);
                return;
            }
        }
        revert("Commitment not found");
    }

    function getCommitmentCount() public view returns (uint256) {
        return commitments.length;
    }
}

//  ZKPStorage.sol
contract ZKPStorage {
    struct ZKP {
        string nodeId;
        string deviceId;
        string deviceType;
        string hardwareVersion;
        string firmwareVersion;
        bytes zkp_payload;
        string data_payload;
        string unixtime_payload;
        uint256 timestamp;
    }

    ZKP[] public zkps;

    event ZKPStored(
        string nodeId,
        string deviceId,
        string deviceType,
        string hardwareVersion,
        string firmwareVersion,
        bytes zkp_payload,
        string data_payload,
        string unixtime_payload,
        uint256 timestamp
    );

    function storeZKP(
        string memory nodeId,
        string memory deviceId,
        string memory deviceType,
        string memory hardwareVersion,
        string memory firmwareVersion,
        bytes memory zkp_payload,
        string memory data_payload,
        string memory unixtime_payload
    ) public {
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

        emit ZKPStored(
            nodeId,
            deviceId,
            deviceType,
            hardwareVersion,
            firmwareVersion,
            zkp_payload,
            data_payload,
            unixtime_payload,
            block.timestamp
        );
    }

    function getZKPCount() public view returns (uint256) {
        return zkps.length;
    }

    function getZKP(uint256 index) public view returns (
        string memory nodeId,
        string memory deviceId,
        string memory deviceType,
        string memory hardwareVersion,
        string memory firmwareVersion,
        bytes memory zkp_payload,
        string memory data_payload,
        string memory unixtime_payload,
        uint256 timestamp
    ) {
        require(index < zkps.length, "Index out of bounds");

        ZKP storage zkp = zkps[index];
        return (
            zkp.nodeId,
            zkp.deviceId,
            zkp.deviceType,
            zkp.hardwareVersion,
            zkp.firmwareVersion,
            zkp.zkp_payload,
            zkp.data_payload,
            zkp.unixtime_payload,
            zkp.timestamp
        );
    }
}

contract DeviceNFT is Ownable, ERC721URIStorage {
    
    uint256 private _tokenIdCounter = 1;

    struct DeviceInfo {
        string deviceId;
        string deviceIdType;
        string manufacturer;
        string modelNumber;
        string deviceType;
    }

    mapping(uint256 => DeviceInfo) public deviceDetails;

    constructor(address initialOwner) ERC721("DeviceNFT", "DNFT") Ownable(initialOwner) {}

    function mintDeviceNFT(
        address to,
        string memory deviceId,
        string memory deviceIdType,
        string memory manufacturer,
        string memory modelNumber,
        string memory deviceType,
        string memory tokenURI
    ) public onlyOwner {
        uint256 newTokenId = _tokenIdCounter;
        _safeMint(to, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        deviceDetails[newTokenId] = DeviceInfo(
            deviceId,
            deviceIdType,
            manufacturer,
            modelNumber,
            deviceType
        );

        _tokenIdCounter++;
    }

    // _msgSender
    function _msgSender() internal view override(Context) returns (address) {
        return super._msgSender();
    }
}


   contract Protocol is ServiceManagement, CommitmentStorage, ZKPStorage {
    constructor(address initialOwner)
        ServiceManagement(initialOwner)
        CommitmentStorage()
        ZKPStorage()
    {}
}