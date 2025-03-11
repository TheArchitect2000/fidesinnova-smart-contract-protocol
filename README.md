<p align="center">
  <a href="https://fidesinnova.io/" target="blank"><img src="g-c-web-back.png" /></a>
</p>

# Fides Innova Smart Contract Protocol

<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/v/@nestjs/core.svg" alt="NPM Version" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/l/@nestjs/core.svg" alt="Package License" /></a>
<a href="https://www.npmjs.com/~nestjscore" target="_blank"><img src="https://img.shields.io/npm/dm/@nestjs/common.svg" alt="NPM Downloads" /></a>
<a href="https://circleci.com/gh/nestjs/nest" target="_blank"><img src="https://img.shields.io/circleci/build/github/nestjs/nest/master" alt="CircleCI" /></a>
<a href="https://coveralls.io/github/nestjs/nest?branch=master" target="_blank"><img src="https://coveralls.io/repos/github/nestjs/nest/badge.svg?branch=master#9" alt="Coverage" /></a>
<a href="https://discord.com/invite/NQdM6JGwcs" target="_blank"><img src="https://img.shields.io/badge/discord-online-brightgreen.svg" alt="Discord"/></a>
<a href="https://twitter.com/Fidesinnova" target="_blank"><img src="https://img.shields.io/twitter/follow/nestframework.svg?style=social&label=Follow"></a>

This smart contract includes all the necessary Solidity code on the Fides Innova chain to:
- Share/unshare IoT devices
- Publish/unpublish service codes (Blockly and JavaScript)
- Submit IoT/AI-generated data along with their ZKPs
- Submit IoT/AI firmware/program ZKP commitments
- Create NFTs for IoT devices or AI computations
- Transfer IoT device NFTs between users’ ownership wallets
- Bind users’ identity wallets to their ownership wallets


## Protocol Contract Overview

The `Protocol` contract inherits from the following contracts:

- **ServiceManagement**: Manages service-related functions.
- **CommitmentStorage**: Manages commitment records for IoT devices.
- **ZKPStorage**: Manages Zero-Knowledge Proof (ZKP) data for IoT devices.
- **Sign_identity**: Handles the registration of identities.
- **Sign_ownership**: Handles the registration of ownerships.
- **IdentityBinding**: Binds identities to ownerships.
- **DeviceNFT**: Manages NFT creation and transfer for IoT devices.

The `Protocol` contract integrates these functionalities into one unified service for managing commitments, ZKPs, identities, ownerships, and NFTs for IoT devices.

## Functions Overview

### ServiceManagement Contract

#### `publishService`
**Description**: Publishes a new IoT-related service to the blockchain.

**Input Parameters**:
- `serviceId`: Unique identifier of the service.
- `serviceMetadata`: Metadata describing the service.
- `publisher`: Address of the service publisher.
**Returns**:
- `bool`: Returns true if the service is successfully published.

#### `unpublishService`
**Description**: Removes a published service from the blockchain.

**Input Parameters**:
- `serviceId`: Unique identifier of the service.

**Returns**:
- `bool`: Returns true if the service is successfully removed..



### DeviceManager Contract

#### `registerDevice`
**Description**: Registers an IoT device under an ownership wallet and assigns it a unique identifier.

**Input Parameters**:
- `deviceId`: Unique identifier of the IoT device.
- `owner`: Address of the device owner.
- `deviceMetadata`:  Metadata containing device information.
**Returns**:
- `bool`: Returns true if the device is successfully registered.


#### `transferDevice`
**Description**: Transfers the ownership of an IoT device NFT to another wallet.

**Input Parameters**:
- `deviceId:`: Unique identifier of the IoT device.
- `newOwner:`: Address of the new owner.

**Returns**:
- `bool`: Returns true if the transfer is successful.


### CommitmentStorage Contract

#### `storeCommitment`
**Description**: Stores a commitment for an IoT device with its specific details. It saves the commitment data only if the `commitmentID` is not already registered.

**Input Parameters**:
- `commitmentID`: The unique identifier for the commitment.
- `nodeId`: The unique identifier for the IoT node.
- `iot_manufacturer_name`: The name of the IoT manufacturer.
- `iot_device_name`: The name of the IoT device.
- `device_hardware_version`: The hardware version of the IoT device.
- `firmware_version`: The firmware version of the IoT device.
- `commitmentData`: The commitment data associated with the device.

**Returns**:
- `bool`: Returns true if the commitment is successfully stored.

#### `getCommitment`
**Description**: Retrieves the commitment data for a given IoT device based on the provided `commitmentID` and `nodeId`.

**Input Parameters**:
- `commitmentID`: The unique identifier for the commitment.
- `nodeId`: The unique identifier for the IoT node.

**Returns**:
- `commitmentIDResult`: The commitment ID.
- `nodeIdResult`: The node ID.
- `iot_manufacturer_name`: Manufacturer name.
- `iot_device_name`: Device name.
- `device_hardware_version`: Device hardware version.
- `firmware_version`: Firmware version.
- `commitmentData`: The commitment data.
- `timestamp`: Timestamp when the commitment was stored.

#### `removeCommitment`
**Description**: Removes the commitment data for a specific IoT device based on the provided `commitmentID` and `nodeId`.

**Input Parameters**:
- `commitmentID`: The unique identifier for the commitment.
- `nodeId`: The unique identifier for the IoT node.

**Returns**: None.

#### `getCommitmentCount`
**Description**: Retrieves the total number of commitments stored.

**Returns**:
- `uint256`: The total count of stored commitments.

---

### ZKPStorage Contract

#### `storeZKP`
**Description**: Stores Zero-Knowledge Proof (ZKP) data for an IoT device.

**Input Parameters**:
- `nodeId`: The unique identifier for the IoT node.
- `deviceId`: The unique identifier for the IoT device.
- `deviceType`: The type of the IoT device.
- `hardwareVersion`: The hardware version of the IoT device.
- `firmwareVersion`: The firmware version of the IoT device.
- `zkp_payload`: The Zero-Knowledge Proof data (bytes).
- `data_payload`: The associated data payload.
- `unixtime_payload`: The Unix timestamp payload.

**Returns**: None.

#### `getZKPCount`
**Description**: Retrieves the total number of ZKP entries stored.

**Returns**:
- `uint256`: The total count of stored ZKP entries.

#### `getZKP`
**Description**: Retrieves a specific ZKP data entry based on its index.

**Input Parameters**:
- `index`: The index of the ZKP data entry to retrieve.

**Returns**:
- `nodeId`: The unique identifier for the IoT node.
- `deviceId`: The unique identifier for the IoT device.
- `deviceType`: The type of the IoT device.
- `hardwareVersion`: The hardware version of the IoT device.
- `firmwareVersion`: The firmware version of the IoT device.
- `zkp_payload`: The Zero-Knowledge Proof data (bytes).
- `data_payload`: The associated data payload.
- `unixtime_payload`: The Unix timestamp payload.
- `timestamp`: Timestamp when the ZKP was stored.

---

### Identity Management Contracts

#### `register_identity`
**Description**: Registers a unique identity for a given IoT device. Ensures that the identity is not already registered.

**Input Parameters**:
- `identity_address`: The address associated with the identity.
- `node_id`: The unique identifier for the IoT node.

**Returns**: None.

#### `register_ownership`
**Description**: Registers the ownership for a given IoT device and ensures the ownership is not already registered.

**Input Parameters**:
- `identity_address`: The address of the identity.
- `node_id`: The unique identifier for the IoT node.
- `ownership_address`: The address associated with the ownership.

**Returns**: None.

#### `bind_identity_ownership`
**Description**: Binds an identity to an ownership address. Checks if the binding has been done already.

**Input Parameters**:
- `ownership_address`: The address associated with the ownership.

**Returns**: None.

---

### Device NFT Management

#### `createNFT`
**Description**: Creates a unique NFT for an IoT device. Ensures that the NFT has not been created for the given device before.

**Input Parameters**:
- `ownership_address`: The address associated with the ownership.

**Returns**: None.

#### `transferNFT`
**Description**: Transfers ownership of an IoT device's NFT to a new ownership address.

**Input Parameters**:
- `nft_id`: The unique identifier for the NFT.
- `receiver_ownership_address`: The address of the new owner.

**Returns**: None.

---

## Smart Contract Inheritance

The `Protocol` contract inherits from the following contracts:

- **ServiceManagement**: Manages service-related functions.
- **CommitmentStorage**: Manages commitment records for IoT devices.
- **ZKPStorage**: Manages Zero-Knowledge Proof (ZKP) data for IoT devices.
- **Sign_identity**: Handles the registration of identities.
- **Sign_ownership**: Handles the registration of ownerships.
- **IdentityBinding**: Binds identities to ownerships.
- **DeviceNFT**: Manages NFT creation and transfer for IoT devices.

---


