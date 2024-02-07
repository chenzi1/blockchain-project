// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudentToken.sol";
import "./StudentRegistrationResult.sol";

contract SchoolAllocation {
    address public owner;
    address public studentTokenContract;
    address public studentContract;

    enum Phase {
        PreRegistration,
        Registration,
        Allocation,
        Completed
    }

    Phase public currentPhase;
    uint256 public year;

    struct StudentRegistration {
        bool isRegistered;
        bytes32 nricHash;
        string residentialAddress;
        uint256 school;
        uint256 distanceToSchool;
    }

    struct SchoolRegistration {
        string schoolName;
        uint256 vacancies;
        bytes32[] students;
    }

    struct AllocationResult {
        bytes32 nricHash;
        uint256 schoolId;
    }

    mapping(address => StudentRegistration) public singaporeCitizenRegistrations;
    mapping(address => StudentRegistration) public permanentResidentRegistrations;

    address[] public singaporeCitizenAddresses;
    address[] public permanentResidentAddresses;
    address[] public citizenGroup1;
    address[] public citizenGroup2;
    address[] public citizenGroup3;
    address[] public prGroup1;
    address[] public prGroup2;
    address[] public prGroup3;

    AllocationResult[] public allocationResults;

    address[] public schoolAddress;

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

    event StudentRegistered(address indexed studentAddress, bytes32 nricHash, string residentialAddress, uint256 school);
    event AllocationCompleted();
    event RegistrationEdited(address indexed studentAddress, string newResidentialAddress, uint256 newSchool);
    event RegistrationWithdrawn(address indexed studentAddress);
    event SchoolVacanciesEdited(uint256 schoolId, uint256 oldVacancies, uint256 newVacancies);
    event SchoolRegistered(uint256 schoolId, uint256 vacancies);

    constructor(uint256 _year, address _studentTokenContract, address _studentContract) {
        owner = msg.sender;
        currentPhase = Phase.PreRegistration;
        year = _year;
        studentTokenContract = _studentTokenContract;
        studentContract = _studentContract;
    }

    function registerSchool(string memory _name, uint256 _vacancies) external onlyOwner onlyDuringPhase(Phase.PreRegistration) {
        require(_vacancies > 0, "Vacancies must be greater than 0");

        numSchools++;
        schoolRegistrations[numSchools] = SchoolRegistration(_name, _vacancies, new bytes32[](0));

        emit SchoolRegistered(numSchools, _vacancies);
    }

    function registerStudent(string memory _nricHash, string memory _residentialAddress, uint256 _school, uint256 _distanceToSchool, bool _isSingaporeCitizen) external onlyDuringPhase(Phase.Registration) {
        require(_isSingaporeCitizen || _school != 0, "School must be specified for Permanent Residents");

        StudentToken(studentTokenContract).approve(address(this), 1);
        require(StudentToken(studentTokenContract).transferFrom(msg.sender, address(this), 1), "Token transfer failed");

        if (_isSingaporeCitizen) {
            require(singaporeCitizenRegistrations[msg.sender].nricHash == bytes32(0), "Singapore citizen already registered");
            singaporeCitizenRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(_nricHash)), _residentialAddress, _school, _distanceToSchool);
            singaporeCitizenAddresses.push(msg.sender);
        } else {
            require(permanentResidentRegistrations[msg.sender].nricHash == bytes32(0), "Permanent resident already registered");
            permanentResidentRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(_nricHash)), _residentialAddress, _school, _distanceToSchool);
            permanentResidentAddresses.push(msg.sender);
        }

        emit StudentRegistered(msg.sender, keccak256(abi.encodePacked(_nricHash)), _residentialAddress, _school);
    }

    function editRegistration(string memory _newResidentialAddress, uint256 _newSchool, uint256 _newDistanceToSchool) external onlyDuringPhase(Phase.Registration) {
        require(singaporeCitizenRegistrations[msg.sender].isRegistered || permanentResidentRegistrations[msg.sender].isRegistered, "Student not registered");

        if (singaporeCitizenRegistrations[msg.sender].isRegistered) {
            singaporeCitizenRegistrations[msg.sender].residentialAddress = _newResidentialAddress;
            singaporeCitizenRegistrations[msg.sender].school = _newSchool;
            singaporeCitizenRegistrations[msg.sender].distanceToSchool = _newDistanceToSchool;
        } else {
            permanentResidentRegistrations[msg.sender].residentialAddress = _newResidentialAddress;
            permanentResidentRegistrations[msg.sender].school = _newSchool;
            permanentResidentRegistrations[msg.sender].distanceToSchool = _newDistanceToSchool;
        }

        emit RegistrationEdited(msg.sender, _newResidentialAddress, _newSchool);
    }

    function editSchoolVacancies(uint256 schoolId, uint256 newVacancies) external onlyOwner {
        uint256 oldVacancies = schoolRegistrations[schoolId].vacancies;
        schoolRegistrations[schoolId].vacancies = newVacancies;

        emit SchoolVacanciesEdited(schoolId, oldVacancies, newVacancies);
    }

    function viewRegistration() external view returns (bool isRegistered, bytes32 nricHash, string memory residentialAddress, uint256 school, uint256 distanceToSchool) {
        if (singaporeCitizenRegistrations[msg.sender].isRegistered) {
            return (
                true,
                singaporeCitizenRegistrations[msg.sender].nricHash,
                singaporeCitizenRegistrations[msg.sender].residentialAddress,
                singaporeCitizenRegistrations[msg.sender].school,
                singaporeCitizenRegistrations[msg.sender].distanceToSchool
            );
        } else if (permanentResidentRegistrations[msg.sender].isRegistered) {
            return (
                true,
                permanentResidentRegistrations[msg.sender].nricHash,
                permanentResidentRegistrations[msg.sender].residentialAddress,
                permanentResidentRegistrations[msg.sender].school,
                permanentResidentRegistrations[msg.sender].distanceToSchool
            );
        } else {
            return (false, bytes32(0), "", 0, 0);
        }
    }

    function withdrawRegistration() external onlyDuringPhase(Phase.Registration) {
        require(singaporeCitizenRegistrations[msg.sender].isRegistered || permanentResidentRegistrations[msg.sender].isRegistered, "Student not registered");

        if (singaporeCitizenRegistrations[msg.sender].isRegistered) {
            delete singaporeCitizenRegistrations[msg.sender];
            removeAddressFromArray(singaporeCitizenAddresses, msg.sender);
        } else {
            delete permanentResidentRegistrations[msg.sender];
            removeAddressFromArray(permanentResidentAddresses, msg.sender);
        }

        // Refund the registration token to the student
        require(StudentToken(studentTokenContract).transfer(msg.sender, 1), "Token transfer failed");

        emit RegistrationWithdrawn(msg.sender);
    }

    function startAllocation() external onlyOwner onlyDuringPhase(Phase.Registration) {
        currentPhase = Phase.Allocation;

        // Sort students based on distance to school (1 to 3)
        sortStudentsByDistance();

        // Now, proceed with allocation
        // Allocate school vacancies based on distance for citizens group
        allocateSchoolVacancies(citizenGroup1, true, 1);
        allocateSchoolVacancies(citizenGroup2, true, 1);
        allocateSchoolVacancies(citizenGroup3, true, 1);

        // Allocate school vacancies based on distance for permanent residents group
        allocateSchoolVacancies(prGroup1, true, 1);
        allocateSchoolVacancies(prGroup2, true, 1);
        allocateSchoolVacancies(prGroup3, true, 1);
    }

    function completeAllocation() external onlyOwner onlyDuringPhase(Phase.Allocation) {
        currentPhase = Phase.Completed;

        //Stores allocation results in student contract
        for (uint256 i = 0; i < allocationResults.length; i++) {
            StudentRegistrationResult(studentContract).storeRegistrationResult(
                allocationResults[i].nricHash,
                allocationResults[i].schoolId
            );
        }

        emit AllocationCompleted();
    }

    function getStudentsBySchool(uint256 schoolId) external view onlyOwner onlyDuringPhase(Phase.Completed) returns(bytes32[] memory students) {
        return schoolRegistrations[schoolId].students;
    }

    //Simulates calling external API to calculate and retrieve distance from student residential address to school of choice
    function populateDistanceToSchool() external {
        for (uint8 i = 1; i < singaporeCitizenAddresses.length; i++) {
            singaporeCitizenRegistrations[singaporeCitizenAddresses[i]].distanceToSchool = i;
        }

        for (uint8 i = 1; i < permanentResidentAddresses.length; i++) {
            permanentResidentRegistrations[permanentResidentAddresses[i]].distanceToSchool = i;
        }
    }

    function removeAddressFromArray(address[] storage array, address value) internal {
        for (uint i = 0; i < array.length; i++) {
            if (array[i] == value) {
                if (i != array.length - 1) {
                    array[i] = array[array.length - 1];
                }
                array.pop();
                return;
            }
        }
    }

    function sortStudentsByDistance() internal {
        // Sort Singapore citizen students
        for (uint256 i = 0; i < singaporeCitizenAddresses.length; i++) {
            address studentAddress = singaporeCitizenAddresses[i];
            uint256 distance = singaporeCitizenRegistrations[studentAddress].distanceToSchool;
            if (distance < 1) {
                citizenGroup1.push(studentAddress);
            } else if (distance >= 1 && distance <= 2) {
                citizenGroup2.push(studentAddress);
            } else {
                citizenGroup3.push(studentAddress);
            }
        }

        // Sort permanent resident students
        for (uint256 i = 0; i < permanentResidentAddresses.length; i++) {
            address studentAddress = permanentResidentAddresses[i];
            uint256 distance = permanentResidentRegistrations[studentAddress].distanceToSchool;
            if (distance < 1) {
                prGroup1.push(studentAddress);
            } else if (distance >= 1 && distance <= 2) {
                prGroup2.push(studentAddress);
            } else {
                prGroup3.push(studentAddress);
            }
        }
    }

    function allocateSchoolVacancies(address[] storage studentsGroup, bool isCitizen, uint8 schoolId) internal {
        uint256 remainingVacancies = schoolRegistrations[schoolId].vacancies;

        for (uint256 i = 0; i < studentsGroup.length; i++) {
            address studentAddress = studentsGroup[i];

            // If vacancies are available, allocate the school to the student
            if (remainingVacancies > 0) {
                // Store the ballot result
                if (isCitizen) {
                    allocationResults.push(AllocationResult(singaporeCitizenRegistrations[studentAddress].nricHash,schoolId));
                    schoolRegistrations[schoolId].students.push(singaporeCitizenRegistrations[studentAddress].nricHash);
                } else {
                    allocationResults.push(AllocationResult(permanentResidentRegistrations[studentAddress].nricHash,schoolId));
                    schoolRegistrations[schoolId].students.push(permanentResidentRegistrations[studentAddress].nricHash);
                }
                remainingVacancies--;
            } else {
                // Start a ballot to randomly fill up the remaining vacancies from the student group
                startRandomBallot(studentsGroup, isCitizen, i, schoolId);
                break;
            }
        }
    }

    function startRandomBallot(address[] storage studentsGroup, bool isCitizen, uint256 vacancies, uint256 schoolId) internal {
        require(vacancies > 0, "No vacancies available");

        uint256 remainingVacancies = vacancies;

        // Iterate through the students in the group and randomly allocate schools
        for (uint256 i = 0; i < studentsGroup.length; i++) {
            address studentAddress = studentsGroup[i];

            // If all vacancies are filled, exit the loop
            if (remainingVacancies == 0) {
                break;
            }

            // Choose a random index within the students group
            uint256 randomIndex = (uint256(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, i))) % studentsGroup.length);

            // Retrieve the student address at the random index
            address selectedStudent = studentsGroup[randomIndex];

            // Swap the selected student with the current student
            studentsGroup[randomIndex] = studentAddress;
            studentsGroup[i] = selectedStudent;

            // Store the ballot result
            if (isCitizen) {
                allocationResults.push(AllocationResult(singaporeCitizenRegistrations[studentAddress].nricHash,schoolId));
                schoolRegistrations[schoolId].students.push(singaporeCitizenRegistrations[studentAddress].nricHash);
            } else {
                allocationResults.push(AllocationResult(permanentResidentRegistrations[studentAddress].nricHash,schoolId));
                schoolRegistrations[schoolId].students.push(permanentResidentRegistrations[studentAddress].nricHash);
            }
            remainingVacancies--;
        }
        schoolRegistrations[schoolId].vacancies = remainingVacancies;

    }
}
