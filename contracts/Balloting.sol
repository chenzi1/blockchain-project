// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC735/ERC735.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Balloting is Ownable {
    event BallotResultAssigned(address indexed studentIdentity, address indexed school, uint256 result);

    enum Citizenship { SingaporeCitizen, PermanentResident }

    // Struct to store student information
    struct StudentInfo {
        Citizenship citizenship;
        uint256 ballotResult;
        uint256 distanceToSchool; // Distance in kilometers
    }

    // Mapping from student identity to student information
    mapping(address => StudentInfo) private _studentInfo;

    // ERC735 identity contract for the Ministry of Education
    ERC735 public moeIdentityContract;

    // Modifier to ensure that only the Ministry of Education can assign ballot results
    modifier onlyMOE() {
        require(msg.sender == address(moeIdentityContract), "Not authorized");
        _;
    }

    constructor(address _moeIdentityContract) {
        moeIdentityContract = ERC735(_moeIdentityContract);
    }

    // Assign ballot results for students
    function assignBallotResult(address studentIdentity, address school, uint256 result, uint256 distanceToSchool) external onlyMOE {
        require(_studentInfo[studentIdentity].ballotResult == 0, "Ballot result already assigned");
        _studentInfo[studentIdentity].ballotResult = result;
        _studentInfo[studentIdentity].distanceToSchool = distanceToSchool;
        emit BallotResultAssigned(studentIdentity, school, result);
    }

    // Get the assigned ballot result for a student
    function getBallotResult(address studentIdentity) external view returns (uint256) {
        return _studentInfo[studentIdentity].ballotResult;
    }

    // Get the citizenship status for a student
    function getCitizenshipStatus(address studentIdentity) external view returns (Citizenship) {
        return _studentInfo[studentIdentity].citizenship;
    }

    // Get the distance to the school for a student
    function getDistanceToSchool(address studentIdentity) external view returns (uint256) {
        return _studentInfo[studentIdentity].distanceToSchool;
    }

    // Function to determine the priority group of a student
    function getPriorityGroup(address studentIdentity) external view returns (uint256) {
        StudentInfo storage student = _studentInfo[studentIdentity];

        if (student.citizenship == Citizenship.SingaporeCitizen) {
            if (student.distanceToSchool <= 1) {
                return 1; // SC living within 1km
            } else if (student.distanceToSchool > 1 && student.distanceToSchool <= 2) {
                return 2; // SC living between 1km and 2km
            } else {
                return 3; // SC living outside 2km
            }
        } else {
            // Permanent Resident
            if (student.distanceToSchool <= 1) {
                return 4; // PR living within 1km
            } else if (student.distanceToSchool > 1 && student.distanceToSchool <= 2) {
                return 5; // PR living between 1km and 2km
            } else {
                return 6; // PR living outside 2km
            }
        }
    }
}
