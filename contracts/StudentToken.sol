// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract StudentToken is ERC20, Ownable {
    uint256 public registrationTokenCost;

    event TokensTransferred(address indexed from, address indexed to, uint256 amount);

    constructor(string memory _name, string memory _symbol, uint256 _initialSupply, uint256 _tokenCost, address _initialOwner)
    ERC20(_name, _symbol)
    Ownable(_initialOwner)
    {
        _mint(_initialOwner, _initialSupply);
        registrationTokenCost = _tokenCost;
    }

    function setRegistrationTokenCost(uint256 _newCost) external onlyOwner {
        registrationTokenCost = _newCost;
    }

    function transferFrom(address _from, address _to, uint256 _amount) public override returns (bool) {
        require(balanceOf(_from) >= _amount, "Insufficient balance");
        require(_amount <= registrationTokenCost, "Exceeds registration token cost");

        _transfer(_from, _to, _amount);
        emit TokensTransferred(_from, _to, _amount);
        return true;
    }
}
