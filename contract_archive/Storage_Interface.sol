pragma solidity ^0.4.4;

contract Storage_Interface{
    function totalSupply() public constant returns(uint256);
    function balanceOf(address _owner) public constant returns(uint256);
    function acceptedBuyTokens(address _to, uint256 _value) public returns (bool);
    function acceptedUseTokens(address _from, uint256 _value) public returns (bool);
}
