pragma solidity ^0.4.4;

import './StorageV2_Interface.sol';
/******************************************************************************************************************************************************************
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract StorageV2_Service1{
  using SafeMath for uint256;

  bool public addressSet;
  address public owner;
  address public storage_address;       //storage for all transactions
  StorageV2_Interface public storage;

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
    storage = StorageV2_Interface(st);
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

    uint256 destBalance = storage.getBalance(_dest);
    destBalance += destBalance.add(shbt_value);
    require(storage.setBalance(_dest, destBalance));

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
