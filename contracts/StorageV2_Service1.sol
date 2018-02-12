pragma solidity ^0.4.4;

import './StorageV2_Interface.sol';

contract StorageV2_Service1{

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
  * @dev function to purchase ico tokens
  */
  function buy_ico(address _dest) payable public returns(bool){
    require(_dest != address(0));
    require(msg.value >0);
    require(addressSet);

    uint256 shbt_value = convertToSHBT(msg.value, 'ETH');

    StorageV2_Interface st = StorageV2_Interface(storage_address);
    uint256 destBalance = st.getBalance(_dest);
    destBalance += shbt_value;
    require(st.setBalance(_dest, destBalance));

    return true;
  }


  /**
  * @dev internal function to convert money
  */
  function convertToSHBT(uint256 _value, string _type) pure internal returns(uint256){
    require(_value > 0);
    if(keccak256(_type) == keccak256('ETH')){
      return _value * 10;
    }
    else if(keccak256(_type) == keccak256('BTC')){
      return _value * 100;
    }
    else if(keccak256(_type) == keccak256('USD')){
      return _value * 3;
    }
    else{
      return 0;
    }
  }

  function SharebeeToken() public{
    owner = msg.sender;
    addressSet = false;
  }



}
