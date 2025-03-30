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
    }

    // Mapping tokenId => DeviceInfo
    mapping(uint256 => DeviceInfo) public deviceDetails;

    constructor() ERC721("IoTDeviceNFT", "FDSIOT") {
        tokenCounter = 1;
    }

    /**
     * @dev Mint an NFT for an IoT device.
     * The caller becomes the owner of the NFT.
     */
    function mintDeviceNFT(
        string memory deviceId,
        string memory deviceIdType,
        string memory deviceType,
        string memory manufacturer,
        string memory deviceModel
    ) external returns (uint256) {
        uint256 newTokenId = tokenCounter;

        _safeMint(msg.sender, newTokenId);

        deviceDetails[newTokenId] = DeviceInfo(
            deviceId,
            deviceIdType,
            deviceType,
            manufacturer,
            deviceModel
        );

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
        string memory deviceModel
    ) {
        require(tokenCounter >= tokenId && tokenCounter > 1, "Token does not exist");

        DeviceInfo memory info = deviceDetails[tokenId];
        return (
            info.deviceId,
            info.deviceIdType,
            info.deviceType,
            info.manufacturer,
            info.deviceModel
        );
    }
}