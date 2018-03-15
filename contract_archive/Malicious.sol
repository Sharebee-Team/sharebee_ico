pragma solidity ^0.4.4;

import './Storage_Interface.sol';

contract Malicious{
  address public owner;
  address public storage_address;       //storage for all transactions

  function setStorageAddress(address addr) public {
    storage_address = addr;
  }

  function attack() public returns(bool){
    Storage_Interface st = Storage_Interface(storage_address);
    require(st.acceptedBuyTokens(owner, 1000));
    return true;
  }

  function Malicious() public{
    owner = msg.sender;
  }

}
