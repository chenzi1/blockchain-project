// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract StudentContract {
    address public owner;

    struct StudentInfo {
        bytes32 nricHash; // Keccak256 hash of NRIC number
        uint256 ballotResult; // Assigned school based on balloting
    }

    mapping(bytes32 => StudentInfo) public students;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    event StudentBallotResult(bytes32 indexed nricHash, uint256 ballotResult);

    constructor() {
        owner = msg.sender;
    }

    function storeBallotResult(bytes32 _nricHash, uint256 _ballotResult) external onlyOwner {
        require(students[_nricHash].nricHash == bytes32(0), "Ballot result already stored for this NRIC");

        students[_nricHash] = StudentInfo(_nricHash, _ballotResult);

        emit StudentBallotResult(_nricHash, _ballotResult);
    }

    function getBallotResult(bytes32 _nricHash) external view returns (uint256) {
        return students[_nricHash].ballotResult;
    }
}
