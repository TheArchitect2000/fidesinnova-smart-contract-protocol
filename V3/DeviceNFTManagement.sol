// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IoTDeviceNFT is ERC721Enumerable {
    uint256 public tokenCounter;

    struct DeviceInfo {
        string deviceId;
        string deviceIdType;
        string deviceType;
        string manufacturer;
        string deviceModel;
        string ipfsMetadataURL;  // New field for IPFS metadata
    }

    // Mapping tokenId => DeviceInfo
    mapping(uint256 => DeviceInfo) public deviceDetails;
    
    // Mapping to check if a device with the same info already exists
    mapping(bytes32 => bool) private deviceExists;

    constructor() ERC721("IoTDeviceNFT", "FDSIOT") {
        tokenCounter = 1;
    }

    /**
     * @dev Mint an NFT for an IoT device with IPFS metadata
     * The caller becomes the owner of the NFT.
     */
    function mintDeviceNFT(
        string memory deviceId,
        string memory deviceIdType,
        string memory deviceType,
        string memory manufacturer,
        string memory deviceModel,
        string memory ipfsMetadataURL  // New parameter
    ) external returns (uint256) {
        // Create a hash of the device info to check for uniqueness
        bytes32 deviceHash = keccak256(abi.encodePacked(
            deviceId,
            deviceIdType,
            deviceType,
            manufacturer,
            deviceModel
        ));
        
        require(!deviceExists[deviceHash], "Device with these details already exists");

        uint256 newTokenId = tokenCounter;

        _safeMint(msg.sender, newTokenId);

        deviceDetails[newTokenId] = DeviceInfo(
            deviceId,
            deviceIdType,
            deviceType,
            manufacturer,
            deviceModel,
            ipfsMetadataURL  // Store the IPFS URL
        );
        
        // Mark this device info as existing
        deviceExists[deviceHash] = true;

        tokenCounter++;
        return newTokenId;
    }

    /**
     * @dev Get device info by tokenId
     */
    function getDeviceInfo(uint256 tokenId) external view returns (
        string memory deviceId,
        string memory deviceIdType,
        string memory deviceType,
        string memory manufacturer,
        string memory deviceModel,
        string memory ipfsMetadataURL  // New return value
    ) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");

        DeviceInfo memory info = deviceDetails[tokenId];
        return (
            info.deviceId,
            info.deviceIdType,
            info.deviceType,
            info.manufacturer,
            info.deviceModel,
            info.ipfsMetadataURL  // Return the IPFS URL
        );
    }

    /**
     * @dev Override tokenURI to return the IPFS metadata URL
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Token does not exist");
        return deviceDetails[tokenId].ipfsMetadataURL;
    }
}