// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC725/ERC725.sol";
import "@openzeppelin/contracts/token/ERC734/ERC734.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract StudentParentIdentity is ERC725, ERC734 {
    using Strings for uint256;

    // Roles
    uint256 constant ROLE_STUDENT = 1;
    uint256 constant ROLE_PARENT = 2;

    // Mapping from NRIC to the corresponding identity contract
    mapping(string => address) private _nricToIdentity;

    // Events
    event IdentityCreated(address indexed identity, string nric, uint256 role);

    constructor() ERC725("Student Parent Identity", "1.0.0") {}

    // ERC725
    function execute(uint256 operationType, address to, uint256 value, bytes calldata data) external override {
        revert("Execution not supported");
    }

    // ERC734
    function addKey(address key, uint256 purpose, uint256 keyType) external override {
        super.addKey(key, purpose, keyType);
    }

    // Custom function to create an identity for a student or parent
    function createIdentity(string calldata nric, uint256 role) external {
        require(_nricToIdentity[nric] == address(0), "Identity already exists for the given NRIC");
        require(role == ROLE_STUDENT || role == ROLE_PARENT, "Invalid role");

        address identity = address(new Identity(role));
        _nricToIdentity[nric] = identity;
        emit IdentityCreated(identity, nric, role);
    }

    // Custom function to link a student to a parent
    function linkStudentToParent(string calldata studentNRIC, string calldata parentNRIC) external {
        address studentIdentity = _nricToIdentity[studentNRIC];
        address parentIdentity = _nricToIdentity[parentNRIC];

        require(studentIdentity != address(0), "Student identity does not exist");
        require(parentIdentity != address(0), "Parent identity does not exist");

        // Add the parent's key to the student's identity
        IERC734(studentIdentity).addKey(parentNRIC, 1, 1); // Purpose 1: Management, Key type 1: ECDSA
    }

    // Custom function to get the identity contract address associated with an NRIC
    function getIdentityByNRIC(string calldata nric) external view returns (address) {
        return _nricToIdentity[nric];
    }

    // Custom function to get the NRIC associated with an identity contract address
    function getNRICByIdentity(address identity) external view returns (string memory) {
        require(_nricToIdentity[_msgSender()] == identity, "Not authorized to access this identity");

        // For simplicity, this function assumes a one-to-one mapping between NRIC and identity
        // In a real-world scenario, additional logic might be needed
        for (uint256 i = 0; i < super.numKeys(); i++) {
            if (super.keyHasPurpose(_msgSender(), 1, 1)) {
                return super.keyAtIndex(i).toSlice().toString();
            }
        }
        revert("NRIC not found for the given identity");
    }
}