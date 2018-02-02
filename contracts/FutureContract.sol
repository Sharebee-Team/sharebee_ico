pragma solidity ^0.4.4;

import './Storage_Interface.sol';

contract FutureContract{

  bool public addressSet;
  address public owner;
  address public storage_address;       //storage for all transactions

  modifier isOwner(){
      require(msg.sender == owner);
      _;
  }

  /**
  * @dev OWNER ONLY: sets the address of the storage contract
  */
  function setStorageAddress(address st) public isOwner returns(bool){
    require(st != address(0));
    storage_address = st;
    addressSet = true;
  }

  function getStorageAddress() public constant returns(address){
    return storage_address;
  }


  /**
  * @dev function to use the ico tokens somehow
  */
  function some_use_functionality(address _from, uint256 _value) public returns(bool){
    require(_from != address(0));
    require(addressSet);

    Storage_Interface st = Storage_Interface(storage_address);
    require(st.acceptedUseTokens(_from, _value));
    return true;
  }

  function FutureContract() public{
    owner = msg.sender;
    addressSet = false;
  }
}
