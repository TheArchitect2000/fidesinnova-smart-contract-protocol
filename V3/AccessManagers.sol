// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;


/*************************************************************
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