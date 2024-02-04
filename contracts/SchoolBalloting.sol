// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudentToken.sol";
import "./StudentContract.sol";

contract SchoolBalloting {
    address public owner;
    address public studentTokenContract;
    address public studentContract;

    enum Phase {
        Registration,
        Balloting,
        Completed
    }

    Phase public currentPhase;
    uint256 public year;

    struct StudentRegistration {
        bool isRegistered;
        bytes32 nricHash;
        string residentialAddress;
        string citizenship;
    }

    mapping(address => StudentRegistration) public studentRegistrations;
    address[] public studentAddresses;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyDuringPhase(Phase _phase) {
        require(currentPhase == _phase, "Not in the correct phase");
        _;
    }

    event StudentRegistered(address indexed studentAddress, bytes32 nricHash, string residentialAddress, string citizenship);
    event BallotingCompleted();
    event RegistrationEdited(address indexed studentAddress, string newResidentialAddress, string newCitizenship);
    event RegistrationWithdrawn(address indexed studentAddress);

    constructor(uint256 _year, address _studentTokenContract, address _studentContract) {
        owner = msg.sender;
        currentPhase = Phase.Registration;
        year = _year;
        studentTokenContract = _studentTokenContract;
        studentContract = _studentContract;
    }

    function registerStudent(string memory nric, string memory _residentialAddress, string memory _citizenship) external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].nricHash == bytes32(0), "Student already registered");

        StudentToken(studentTokenContract).approve(address(this), 1);
        require(StudentToken(studentTokenContract).transferFrom(msg.sender, address(this), 1), "Token transfer failed");

        studentRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(nric)), _residentialAddress, _citizenship);
        studentAddresses.push(msg.sender);

        emit StudentRegistered(msg.sender, studentRegistrations[msg.sender].nricHash, _residentialAddress, _citizenship);
    }

    function editRegistration(string memory newResidentialAddress, string memory newCitizenship) external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        studentRegistrations[msg.sender].residentialAddress = newResidentialAddress;
        studentRegistrations[msg.sender].citizenship = newCitizenship;

        emit RegistrationEdited(msg.sender, newResidentialAddress, newCitizenship);
    }

    function viewRegistration() external view returns (bool isRegistered, bytes32 nricHash, string memory residentialAddress, string memory citizenship) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        return (
            true,
            studentRegistrations[msg.sender].nricHash,
            studentRegistrations[msg.sender].residentialAddress,
            studentRegistrations[msg.sender].citizenship
        );
    }

    function withdrawRegistration() external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        studentRegistrations[msg.sender].isRegistered = false;

        // Refund the registration token to the student
        require(StudentToken(studentTokenContract).transfer(msg.sender, 1), "Token transfer failed");

        emit RegistrationWithdrawn(msg.sender);
    }

    function startBalloting() external onlyOwner onlyDuringPhase(Phase.Registration) {
        require(studentAddresses.length > 0, "No students registered for balloting");

        currentPhase = Phase.Balloting;
    }

    function completeBalloting() external onlyOwner onlyDuringPhase(Phase.Balloting) {
        require(studentAddresses.length > 0, "No students registered for balloting");

        // Simplified balloting logic: Randomly assign a school (1 to 10, for example)
        for (uint256 i = 0; i < studentAddresses.length; i++) {
            address studentAddress = studentAddresses[i];
            uint256 randomSchool = (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % 10) + 1;

            // Store the ballot result in the StudentContract
            StudentContract(studentContract).storeBallotResult(
                studentRegistrations[studentAddress].nricHash,
                randomSchool
            );
        }

        currentPhase = Phase.Completed;

        emit BallotingCompleted();
    }
}
