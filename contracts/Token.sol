pragma solidity ^0.4.9;
import "./StorageV3.sol";
import "./Receiver_Interface.sol";

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


 /* New ERC23 contract interface */

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) public view returns (uint);

  function name() public view returns (string _name);
  function symbol() public view returns (string _symbol);
  function decimals() public view returns (uint8 _decimals);
  function totalSupply() public view returns (uint256 _supply);

  function transfer(address to, uint value) public returns (bool ok);
  function transfer(address to, uint value, bytes data) public returns (bool ok);
  function transfer(address to, uint value, bytes data, string custom_fallback) public returns (bool ok);

  event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);
}

/*
TODO:
  NOTE: owner is the sharebee multi-sig company wallet
  owner has mint and burn privilages
  sharebee_private has everything and is multi sig wallet
  sharebee_public is the ico balance -- operates like just another user -- all buys are from the public balance
  --CREATE ALLOCATE function that transfers from sharebee_private to specified sharebee_account
  --CREATE RETREIVE function that transfers from specified sharebee_account to sharebee_private
  

  sharebee_family is the family balance
*/

contract Token is ERC223{
  using SafeMath for uint256;

  //contracts
  StorageV3 sharebeeStorage = StorageV3(0);

  //Constants
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  uint256 public constant exchange_supply = 360000000;          //Initial supply of exchange tokens
  uint256 public constant utility_supply =  120000000;           //Initial supply of utility tokens
  bool public mintable;

  //Constructor
  function Token(address _storageAddress) public{
    sharebeeStorage = StorageV3(_storageAddress);
    name = "Sharebee Token";
    decimals = 0;
    symbol = "SHBX";
    totalSupply = 600000000;
    mintable = false;
    sharebeeStorage.setUint(keccack("sharebee_private.balance.SHBX", msg.sender), totalSupply;
  }

    // Function to access name of token .
  function name() public constant returns (string _name) {
      return name;
  }
  // Function to access symbol of token .
  function symbol() public constant returns (string _symbol) {
      return symbol;
  }
  // Function to access decimals of token .
  function decimals() public constant returns (uint8 _decimals) {
      return decimals;
  }
  // Function to access total supply of tokens .
  function totalSupply() public constant returns (uint256 _totalSupply) {
      return totalSupply;
  }

  //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
  function isContract(address _addr) private constant returns (bool is_contract) {
    uint length;
    assembly {
      //retrieve the size of the code on target address, this needs assembly
      length := extcodesize(_addr)
    }
    return (length>0);
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return sharebeeStorage.getUint(keccak("user.balance.SHBX",_owner));
  }

  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data, string _custom_fallback) public returns (bool success) {

    if(isContract(_to)) {
        uint256 _senderBalance = balanceOf(msg.sender);
        uint256 _destBalance = balanceOf(_to);
        if (_senderBalance < _value) revert();
        //compute transaction result
        _senderBalance = _senderBalance.sub(_value);
        _destBalance = _destBalance.add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));

        //set values
        sharebeeStorage.setUint(keccack("user.balance.SHBX", _to), _destBalance);
        sharebeeStorage.setUint(keccack("user.balance.SHBX", msg.sender), _senderBalance);

        Transfer(msg.sender, _to, _value, _data);
        return true;
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  // Function that is called when a user or another contract wants to transfer funds .
  function transfer(address _to, uint _value, bytes _data) public returns (bool success) {
    if(isContract(_to)) {
        return transferToContract(_to, _value, _data);
    }
    else {
        return transferToAddress(_to, _value, _data);
    }
  }
  // Standard function transfer similar to ERC20 transfer with no _data .
  function transfer(address _to, uint _value) public returns (bool success) {
    //standard function transfer similar to ERC20 transfer with no _data
    bytes memory empty;
    if(isContract(_to)) {
        return transferToContract(_to, _value, empty);
    }
    else {
        return transferToAddress(_to, _value, empty);
    }
  }

  //function that is called when transaction target is an address
  function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
    uint256 _senderBalance = balanceOf(msg.sender);
    uint256 _destBalance = balanceOf(_to);
    if (_senderBalance < _value) revert();
    //compute transaction result
    _senderBalance = _senderBalance.sub(_value);
    _destBalance = _destBalance.add(_value);
    //set values
    sharebeeStorage.setUint(keccack("user.balance.SHBX", _to), _destBalance);
    sharebeeStorage.setUint(keccack("user.balance.SHBX", msg.sender), _senderBalance);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
    uint256 _senderBalance = balanceOf(msg.sender);
    uint256 _destBalance = balanceOf(_to);
    if (_senderBalance < _value) revert();
    //compute transaction result
    _senderBalance = _senderBalance.sub(_value);
    _destBalance = _destBalance.add(_value);

    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);
    Transfer(msg.sender, _to, _value, _data);
    return true;
  }
}
