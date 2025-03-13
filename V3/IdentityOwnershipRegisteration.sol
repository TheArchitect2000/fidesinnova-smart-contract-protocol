// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;



/*************************************************************
 * @title IdentityOwnershipRegisteration
 * @dev A smart contract for registering and managing identities with ownerships binding.
 *      - A user can register an identity associated with a unique node ID.
 *      - Ownership can be assigned to a registered identity.
 *      - The identity and ownership can be bound together once both are registered.
 */

contract IdentityOwnershipRegisteration {
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
     * @param _nodeId: The node ID associated with this identity.
     */
    function registerIdentity(uint256 _nodeId) public {
        require(identities[msg.sender].identityAddress == address(0), "Identity already registered.");
        require(!nodeExists[_nodeId], "Node ID already registered.");

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
     * @param _identityAddress: The identity address for which ownership is being assigned.
     */
    function registerOwnership(address _identityAddress) public {
        require(identities[_identityAddress].identityAddress != address(0), "Identity does not exist.");
        require(identities[_identityAddress].ownershipAddress == address(0), "Ownership already registered.");

        identities[_identityAddress].ownershipAddress = msg.sender;

        emit OwnershipRegistered(_identityAddress, msg.sender);
    }

    /**
     * @dev Binds identity and ownership if both addresses match the stored identity.
     * @param _ownershipAddress: The ownership address to bind with the identity.
     */
    function bindIdentityOwnership(address _ownershipAddress) public {
        Identity storage identity = identities[msg.sender];

        require(identity.identityAddress != address(0), "Identity does not exist.");
        require(identity.ownershipAddress == _ownershipAddress, "Ownership address mismatch.");
        require(!identity.binding, "Already bound.");

        identity.binding = true;

        emit IdentityBound(msg.sender, _ownershipAddress);
    }
}

