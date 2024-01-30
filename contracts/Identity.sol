// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC725/ERC725.sol";
import "@openzeppelin/contracts/token/ERC734/ERC734.sol";
import "@openzeppelin/contracts/token/ERC735/ERC735.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Identity is ERC725, ERC734, ERC735, Ownable {
    enum Citizenship { SingaporeCitizen, PermanentResident }

    // Additional data
    string private _name;
    string private _additionalInfo;
    Citizenship private _citizenship;
    string private _residentialAddress;

    // Role of the identity (1 for student, 2 for parent)
    uint256 private _role;

    // Event
    event DataUpdated(address indexed identity, string name, string additionalInfo, Citizenship citizenship, string residentialAddress);

    constructor(uint256 role, Citizenship citizenship, string memory residentialAddress) ERC725("Student Parent Identity", "1.0.0") {
        _role = role;
        _citizenship = citizenship;
        _residentialAddress = residentialAddress;
    }

    // Custom function to set basic information
    function setBasicInformation(string calldata name, string calldata additionalInfo) external {
        require(_msgSender() == owner() || IERC734(owner()).keyHasPurpose(_msgSender(), 2, 1), "Not authorized to update information");
        _name = name;
        _additionalInfo = additionalInfo;
        emit DataUpdated(address(this), name, additionalInfo, _citizenship, _residentialAddress);
    }

    // Custom function to set citizenship status
    function setCitizenshipStatus(Citizenship citizenship) external onlyOwner {
        _citizenship = citizenship;
        emit DataUpdated(address(this), _name, _additionalInfo, _citizenship, _residentialAddress);
    }

    // Custom function to set residential address
    function setResidentialAddress(string calldata residentialAddress) external onlyOwner {
        _residentialAddress = residentialAddress;
        emit DataUpdated(address(this), _name, _additionalInfo, _citizenship, _residentialAddress);
    }

    // Custom function to get basic information
    function getBasicInformation() external view returns (string memory, string memory) {
        return (_name, _additionalInfo);
    }

    // Custom function to get citizenship status
    function getCitizenshipStatus() external view returns (Citizenship) {
        return _citizenship;
    }

    // Custom function to get residential address
    function getResidentialAddress() external view returns (string memory) {
        return _residentialAddress;
    }
}