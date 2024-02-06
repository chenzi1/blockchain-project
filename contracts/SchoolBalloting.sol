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
        uint256 school;
    }

    struct SchoolRegistration {
        uint256 schoolId;
        uint256 vacancies;
    }

    mapping(address => StudentRegistration) public studentRegistrations;
    address[] public studentAddresses;

    mapping(uint256 => SchoolRegistration) public schoolRegistrations;
    uint256 public numSchools;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier onlyDuringPhase(Phase _phase) {
        require(currentPhase == _phase, "Not in the correct phase");
        _;
    }

    event StudentRegistered(address indexed studentAddress, bytes32 nricHash, string residentialAddress, string citizenship, uint256 school);
    event BallotingCompleted();
    event RegistrationEdited(address indexed studentAddress, string newResidentialAddress, string newCitizenship, uint256 newSchool);
    event RegistrationWithdrawn(address indexed studentAddress);
    event SchoolRegistered(uint256 schoolId, uint256 vacancies);

    constructor(uint256 _year, address _studentTokenContract, address _studentContract) {
        owner = msg.sender;
        currentPhase = Phase.Registration;
        year = _year;
        studentTokenContract = _studentTokenContract;
        studentContract = _studentContract;
    }

    function registerStudent(string memory nric, string memory _residentialAddress, string memory _citizenship, uint256 _school) external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].nricHash == bytes32(0), "Student already registered");

        StudentToken(studentTokenContract).approve(address(this), 1);
        require(StudentToken(studentTokenContract).transferFrom(msg.sender, address(this), 1), "Token transfer failed");

        studentRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(nric)), _residentialAddress, _citizenship, _school);
        studentAddresses.push(msg.sender);

        emit StudentRegistered(msg.sender, studentRegistrations[msg.sender].nricHash, _residentialAddress, _citizenship, _school);
    }

    function editRegistration(string memory newResidentialAddress, string memory newCitizenship, uint256 newSchool) external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        studentRegistrations[msg.sender].residentialAddress = newResidentialAddress;
        studentRegistrations[msg.sender].citizenship = newCitizenship;
        studentRegistrations[msg.sender].school = newSchool;

        emit RegistrationEdited(msg.sender, newResidentialAddress, newCitizenship, newSchool);
    }

    function viewRegistration() external view returns (bool isRegistered, bytes32 nricHash, string memory residentialAddress, string memory citizenship, uint256 school) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        return (
            true,
            studentRegistrations[msg.sender].nricHash,
            studentRegistrations[msg.sender].residentialAddress,
            studentRegistrations[msg.sender].citizenship,
            studentRegistrations[msg.sender].school
        );
    }

    function withdrawRegistration() external onlyDuringPhase(Phase.Registration) {
        require(studentRegistrations[msg.sender].isRegistered, "Student not registered");

        studentRegistrations[msg.sender].isRegistered = false;

        // Refund the registration token to the student
        require(StudentToken(studentTokenContract).transfer(msg.sender, 1), "Token transfer failed");

        emit RegistrationWithdrawn(msg.sender);
    }

    function registerSchool(uint256 _schoolId, uint256 _vacancies) external onlyOwner onlyDuringPhase(Phase.Registration) {
        require(schoolRegistrations[_schoolId].schoolId == 0, "School already registered");

        schoolRegistrations[_schoolId] = SchoolRegistration(_schoolId, _vacancies);
        numSchools++;

        emit SchoolRegistered(_schoolId, _vacancies);
    }

    function startBalloting() external onlyOwner onlyDuringPhase(Phase.Registration) {
        require(studentAddresses.length > 0, "No students registered for balloting");

        currentPhase = Phase.Balloting;
    }

    function completeBalloting() external onlyOwner onlyDuringPhase(Phase.Balloting) {
        require(studentAddresses.length > 0, "No students registered for balloting");

        // Simplified balloting logic: Randomly assign a school (1 to numSchools, for example)
        for (uint256 i = 0; i < studentAddresses.length; i++) {
            address studentAddress = studentAddresses[i];
            uint256 randomSchool = (uint256(keccak256(abi.encodePacked(block.difficulty, block.timestamp, i))) % numSchools) + 1;

            // Store the ballot result and school in the StudentContract
            StudentContract(studentContract).storeBallotResult(
                studentRegistrations[studentAddress].nricHash,
                randomSchool
            );
        }

        currentPhase = Phase.Completed;

        emit BallotingCompleted();
    }
}
