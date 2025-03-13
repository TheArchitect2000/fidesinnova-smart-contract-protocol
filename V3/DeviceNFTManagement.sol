// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*************************************************************
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
        require(!deviceExists[deviceHash], "Device already exists.");

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
        require(nftId < nextNFTId, "NFT does not exist.");
        require(msg.sender == devices[nftId].ownershipAddress, "Only the owner can transfer this NFT.");
        require(receiverOwnershipAddress != address(0), "Invalid new owner address.");

        address previousOwner = devices[nftId].ownershipAddress;
        devices[nftId].ownershipAddress = receiverOwnershipAddress;

        emit NFTTransferred(nftId, previousOwner, receiverOwnershipAddress);
    }
}

