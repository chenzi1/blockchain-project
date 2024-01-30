// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Balloting.sol"; // Import the Balloting contract

contract Registration is Ownable {
    event StudentRegistered(address indexed studentIdentity, address indexed school);
    event StudentRegistrationEdited(address indexed studentIdentity, address indexed school);
    event StudentRegistrationWithdrawn(address indexed studentIdentity, address indexed school);
    event BallotingRoundStarted(uint256 roundNumber);

    // Mapping from school address to the list of registered students
    mapping(address => address[]) private _registeredStudents;

    // Balloting contract
    Balloting public ballotingContract;

    // Number of rounds of the ballot process
    uint256 private _ballotingRounds;

    constructor(address _ballotingContract) {
        ballotingContract = Balloting(_ballotingContract);
        _ballotingRounds = 0;
    }

    // Register a student for balloting
    function registerStudent(address studentIdentity, address school) external onlyOwner {
        // Additional checks can be implemented here, such as verifying the student's eligibility

        // Register the student
        _registeredStudents[school].push(studentIdentity);
        emit StudentRegistered(studentIdentity, school);
    }

    // Edit a student's registration information
    function editRegistration(address studentIdentity, address newSchool) external onlyOwner {
        // Additional checks can be implemented here, such as verifying the student's eligibility for editing

        // Find the student in the registered list
        uint256 studentIndex = findStudentIndex(studentIdentity);
        require(studentIndex != type(uint256).max, "Student not found");

        // Edit the student's registration information
        address oldSchool = _registeredStudents[newSchool][studentIndex];
        _registeredStudents[newSchool][studentIndex] = studentIdentity;

        emit StudentRegistrationEdited(studentIdentity, oldSchool);
    }

    // Withdraw a student's registration
    function withdrawRegistration(address studentIdentity, address school) external onlyOwner {
        // Additional checks can be implemented here, such as verifying the student's eligibility for withdrawal

        // Find the student in the registered list
        uint256 studentIndex = findStudentIndex(studentIdentity);
        require(studentIndex != type(uint256).max, "Student not found");

        // Remove the student from the registered list
        _registeredStudents[school][studentIndex] = _registeredStudents[school][_registeredStudents[school].length - 1];
        _registeredStudents[school].pop();

        emit StudentRegistrationWithdrawn(studentIdentity, school);
    }

    // Start a new round of the ballot process
    function startBallotingRound() external onlyOwner {
        _ballotingRounds++;
        emit BallotingRoundStarted(_ballotingRounds);
    }

    // Get the list of registered students for a school
    function getRegisteredStudents(address school) external view returns (address[] memory) {
        return _registeredStudents[school];
    }

    // Get the number of rounds of the ballot process
    function getBallotingRounds() external view returns (uint256) {
        return _ballotingRounds;
    }

    // Internal function to find the index of a student in the registered list
    function findStudentIndex(address studentIdentity) private view returns (uint256) {
        for (uint256 i = 0; i < _registeredStudents.length; i++) {
            if (_registeredStudents[i] == studentIdentity) {
                return i;
            }
        }
        return type(uint256).max;
    }
}
