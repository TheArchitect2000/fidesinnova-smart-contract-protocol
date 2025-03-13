// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

/*************************************************************
 * @title ZKPStorage
 * @dev A smart contract for storing and retrieving Zero-Knowledge Proof (ZKP) and IoT device data on the blockchain.
 */
contract ZKPStorage {

     /**
     * @dev Struct to store ZKP details.
     * @param nodeId The ID of the node associated with the commitment.
     * @param deviceId The ID of the IoT device associated with the commitment.
     * @param zkpPayload The Zero-Knowledge Proof data associated with the commitment.
     * @param dataPayload The IoT device's data associated with the zkpPayload.
     * @param timestamp The timestamp when the commitment was stored.
     */
    struct ZKP {
    string nodeId;
    string deviceId;
    string zkpPayload;
    string dataPayload;
    uint256 timestamp;
    }

    ZKP[] public zkps;

    /**
     * @dev Emitted when a new ZKP is stored.
     * @param nodeId The unique identifier of the node.
     * @param deviceId The unique identifier of the IoT device.
     * @param zkpPayload The unique identifier of the IoT device.
     * @param dataPayload The IoT device's data.
     * @param timestamp The timestamp when the ZKP entry was created.
     */
    event ZKPStored(
    string nodeId,
    string deviceId,
    string zkpPayload,
    string dataPayload,
    uint256 timestamp
    );

    /**
     * @dev Stores the ZKP data for an IoT device.
     * @param nodeId The unique identifier of the node.
     * @param deviceId The unique identifier of the IoT device.
     * @param zkpPayload: The Zero-Knowledge Proof data associated with the IoT device.
     * @param dataPayload: The IoT device's data.
     * @param timestamp: The timestamp when the ZKP entry was created.
     */
    function storeZKP(
    string memory nodeId,
    string memory deviceId,
    string memory zkpPayload,
    string memory dataPayload,
    uint256 timestamp
    ) public {
        zkps.push(ZKP({
        nodeId: nodeId,   
        deviceId: deviceId,  
        zkpPayload: zkpPayload,  
        dataPayload: dataPayload,  
        timestamp: timestamp
        }));

        emit ZKPStored(
             nodeId,   
             deviceId,  
             zkpPayload,  
             dataPayload,  
             timestamp
        );
    }

    /**
     * @dev Retrieves the total number of ZKPs stored in the contract.
     * @return The total number of ZKPs stored in the contract.
     */
    function getZKPCount() public view returns (uint256) {
        return zkps.length;
    }

    /*
     * @dev Retrieves the ZKP data for an IoT device based on the provided index.
     * @param index: The index of the ZKP data entry in the array to retrieve.
     * @return deviceId 
     * @return zkpPayload 
     * @return dataPayload 
     * @return timestamp 
     */
    function getZKP(uint256 index) public view returns (
        string memory nodeId,
        string memory deviceId,
        string memory zkpPayload,
        string memory dataPayload,
        uint256 timestamp
    ) {
        require(index < zkps.length, "Index out of bounds");

        ZKP storage zkp = zkps[index];
        return (
            zkp.nodeId,
            zkp.deviceId,
            zkp.zkpPayload,
            zkp.dataPayload,
            zkp.timestamp
        );
    }
}

