// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./StudentToken.sol";
import "./StudentRegistrationResult.sol";

contract SchoolAllocation {
    address public owner;
    address public studentTokenContract;
    address public studentRegistrationResultContract;

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

    mapping(address => StudentRegistration) private singaporeCitizenRegistrations;
    mapping(address => StudentRegistration) private permanentResidentRegistrations;

    address[] private singaporeCitizenAddresses;
    address[] private permanentResidentAddresses;
    address[] private citizenGroup1;
    address[] private citizenGroup2;
    address[] private citizenGroup3;
    address[] private prGroup1;
    address[] private prGroup2;
    address[] private prGroup3;

    AllocationResult[] private allocationResults;

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

    event SchoolRegistrationCompleted();
    event StudentRegistered(address indexed studentAddress, bytes32 nricHash, string residentialAddress, uint256 school);
    event AllocationCompleted();
    event RegistrationEdited(address indexed studentAddress, string newResidentialAddress, uint256 newSchool);
    event RegistrationWithdrawn(address indexed studentAddress);
    event SchoolVacanciesEdited(uint256 schoolId, uint256 oldVacancies, uint256 newVacancies);
    event SchoolRegistered(uint256 schoolId, uint256 vacancies);

    constructor(uint256 _year, address _studentTokenContract, address _studentRegistrationResultContract) {
        owner = msg.sender;
        currentPhase = Phase.PreRegistration;
        year = _year;
        studentTokenContract = _studentTokenContract;
        studentRegistrationResultContract = _studentRegistrationResultContract;
    }

    function registerSchool(string memory _name, uint256 _vacancies) external onlyOwner onlyDuringPhase(Phase.PreRegistration) {
        require(_vacancies > 0, "Vacancies must be greater than 0");

        numSchools++;
        schoolRegistrations[numSchools] = SchoolRegistration(_name, _vacancies, new bytes32[](0));

        emit SchoolRegistered(numSchools, _vacancies);
    }

    function registerStudent(string memory _nric, string memory _residentialAddress, uint256 _school, bool _isSingaporeCitizen) external onlyDuringPhase(Phase.Registration) {
        require(_isSingaporeCitizen || _school != 0, "School must be specified for Permanent Residents");

        StudentToken(studentTokenContract).approve(address(this), 1);
        require(StudentToken(studentTokenContract).transferFrom(msg.sender, address(this), 1), "Token transfer failed");

        if (_isSingaporeCitizen) {
            require(singaporeCitizenRegistrations[msg.sender].nricHash == bytes32(0), "Singapore citizen already registered");
            singaporeCitizenRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(_nric)), _residentialAddress, _school, 0);
            singaporeCitizenAddresses.push(msg.sender);
        } else {
            require(permanentResidentRegistrations[msg.sender].nricHash == bytes32(0), "Permanent resident already registered");
            permanentResidentRegistrations[msg.sender] = StudentRegistration(true, keccak256(abi.encodePacked(_nric)), _residentialAddress, _school, 0);
            permanentResidentAddresses.push(msg.sender);
        }

        emit StudentRegistered(msg.sender, keccak256(abi.encodePacked(_nric)), _residentialAddress, _school);
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

    function startStudentRegistration() external onlyOwner onlyDuringPhase(Phase.PreRegistration) {
        currentPhase = Phase.Registration;

        emit SchoolRegistrationCompleted();
    }

    function startAllocation() external onlyOwner onlyDuringPhase(Phase.Registration) {
        currentPhase = Phase.Allocation;

        // Sort students based on distance to school
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
            StudentRegistrationResult(studentRegistrationResultContract).storeRegistrationResult(
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
        for (uint256 i = 0; i < singaporeCitizenAddresses.length; i++) {
            singaporeCitizenRegistrations[singaporeCitizenAddresses[i]].distanceToSchool = i+1;
        }

        for (uint256 i = 0; i < permanentResidentAddresses.length; i++) {
            permanentResidentRegistrations[permanentResidentAddresses[i]].distanceToSchool = i+1;
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

        if (remainingVacancies != 0) {
            if (remainingVacancies < studentsGroup.length) {
                // Start a ballot to randomly fill up the remaining vacancies from the student group
                startRandomBallot(studentsGroup, isCitizen, remainingVacancies, schoolId);
            } else {
                for (uint256 i = 0; i < studentsGroup.length; i++) {
                    address studentAddress = studentsGroup[i];

                    // If vacancies are available, allocate the school to the student
                    if (isCitizen) {
                        allocationResults.push(AllocationResult(singaporeCitizenRegistrations[studentAddress].nricHash,schoolId));
                        schoolRegistrations[schoolId].students.push(singaporeCitizenRegistrations[studentAddress].nricHash);
                    } else {
                        allocationResults.push(AllocationResult(permanentResidentRegistrations[studentAddress].nricHash,schoolId));
                        schoolRegistrations[schoolId].students.push(permanentResidentRegistrations[studentAddress].nricHash);
                    }
                    remainingVacancies--;
                    schoolRegistrations[schoolId].vacancies = remainingVacancies;
                }
            }
        }
    }

    function startRandomBallot(address[] storage studentsGroup, bool isCitizen, uint256 vacancies, uint256 schoolId) internal {
        require(vacancies > 0, "No vacancies available");
        require(vacancies < studentsGroup.length);

        // Choose a random index within the students group
        uint256[] memory randomIndices = generateRandomIndices(vacancies, studentsGroup.length);

        for (uint256 i = 0; i < randomIndices.length; i++) {

            // Retrieve the student address at the random index
            address studentAddress = studentsGroup[randomIndices[i]];

            // Store the ballot result
            if (isCitizen) {
                allocationResults.push(AllocationResult(singaporeCitizenRegistrations[studentAddress].nricHash,schoolId));
                schoolRegistrations[schoolId].students.push(singaporeCitizenRegistrations[studentAddress].nricHash);
            } else {
                allocationResults.push(AllocationResult(permanentResidentRegistrations[studentAddress].nricHash,schoolId));
                schoolRegistrations[schoolId].students.push(permanentResidentRegistrations[studentAddress].nricHash);
            }
        }
        schoolRegistrations[schoolId].vacancies = 0;
    }

    function generateRandomIndices(uint256 count, uint256 range) internal view returns (uint256[] memory) {
        require(count <= range, "Count must be less than or equal to range");
        uint256[] memory indices = new uint256[](count);
        uint256[] memory tempArray = new uint256[](range);
        uint256 lastIndex = range - 1;

        // Fill tempArray with sequential values from 0 to range - 1
        for (uint256 i = 0; i < range; i++) {
            tempArray[i] = i;
        }

        // Shuffle tempArray and select first 'count' elements
        for (uint256 i = 0; i < count; i++) {
            uint256 randomIndex = uint256(keccak256(abi.encode(blockhash(block.number - 1), block.timestamp, i))) % (lastIndex + 1);
            indices[i] = tempArray[randomIndex];
            tempArray[randomIndex] = tempArray[lastIndex--];
        }

        return indices;
    }

}
