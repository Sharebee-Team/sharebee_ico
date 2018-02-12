pragma solidity ^0.4.4;

contract Storage_Interface{

    function totalSupply() public constant returns (uint256);
    function getBalance(address _owner) public constant returns(uint256);
    function setBalance(address who, uint256 _value) public returns (bool);

}
