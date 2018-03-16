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
  sharebee_public is the public balance -- operates like just another user -- all buys are from the public balance

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
  uint public constant ownerAgreeThreshold = 2;             //threshold to execute consensus actions
  string private constant privateBalanceString = "sharebee_private.balance.SHBX";
  //string private constant publicBalanceString = "sharebee_public.balance.SHBX";
  //consensus admin request
  AdminChangeRequest public adminChangeRequest;

  // Structs
  struct AdminChangeRequest{
    uint256 amount;
    address[] acceptingOwners;
    uint _type;
    string name;
    //  0 is none,
    //1 is allocate amount to specified sharebee account from sharebee_private,
    //2 retrieve amount from specified sharebee account to sharebee_private,
    //3 is mint amount in sharebee_private,
    //4 is burn amount in sharebee_private
  }

  modifier isOwner(){
    require(sharebeeStorage.getAddress(keccak256("owner.address",msg.sender)) != 0x0);
    _;
  }

  //Constructor
  function Token(address _storageAddress) public{
    sharebeeStorage = StorageV3(_storageAddress);
    name = "Sharebee Token";
    decimals = 0;
    symbol = "SHBX";
    totalSupply = 600000000;

    // WHO SHOULD GET THE INITIALSUPPLY
    sharebeeStorage.setUint(keccak256(privateBalanceString), totalSupply);
  }

  //admin ACTIONS
  function mint(uint256 _amount) private {
    uint256 res = sharebeeStorage.getUint(keccak256(privateBalanceString));
    res = res.add(_amount);
    sharebeeStorage.setUint(keccak256(privateBalanceString), res);
  }

  function burn(uint256 _amount) private {
    uint256 res = sharebeeStorage.getUint(keccak256(privateBalanceString));
    require(res >= _amount);
    res = res.sub(_amount);
    sharebeeStorage.setUint(keccak256(privateBalanceString), res);
  }

  //Places funds from sharebee_private into specified sharebee dest
  //String can "sharebee_public.balance.SHBX", "sharebee_family.balance.SHBX", etc.
  function allocateFromPrivate(string destString, uint256 _amount) private{
    uint256 pvt = sharebeeStorage.getUint(keccak256(privateBalanceString));
    uint256 des = sharebeeStorage.getUint(keccak256(destString));
    require(pvt >= _amount);
    pvt = pvt.sub(_amount);
    des = des.add(_amount);
    sharebeeStorage.setUint(keccak256(privateBalanceString), pvt);
    sharebeeStorage.setUint(keccak256(destString), des);
  }

  //Retrieve funds from specified sharebee dest and places them back in sharebee_private
  function consolidateToPrivate(string sourceString, uint256 _amount) private{
    uint256 pvt = sharebeeStorage.getUint(keccak256(privateBalanceString));
    uint256 src = sharebeeStorage.getUint(keccak256(sourceString));
    require(src >= _amount);
    src = src.sub(_amount);
    pvt = pvt.add(_amount);
    sharebeeStorage.setUint(keccak256(sourceString), src);
    sharebeeStorage.setUint(keccak256(privateBalanceString), pvt);
  }

  function resetAdminAction() private {
    //remove admin change request after execution
    adminChangeRequest._type = 0;
    adminChangeRequest.amount = 0;
    adminChangeRequest.name = "";
  }


  function adminChangeAction(uint256 _amount, uint256 _type, string _name) public isOwner returns(bool){
    if(adminChangeRequest._type == _type && adminChangeRequest.amount == _amount && keccak256(adminChangeRequest.name) == keccak256(_name)  && adminChangeRequest._type != 0 && _amount > 0){
      for(uint i = 0; i < adminChangeRequest.acceptingOwners.length; i++){
        if(adminChangeRequest.acceptingOwners[i] == msg.sender){
          return false; //owner has already requested this change
        }
      }
      adminChangeRequest.acceptingOwners.push(msg.sender);
      if(adminChangeRequest.acceptingOwners.length >= ownerAgreeThreshold){
        if(adminChangeRequest._type == 0){
          return false;
        }
        else if(adminChangeRequest._type == 1){
          //1 is allocate amount to specified dest name from sharebee_private,
          allocateFromPrivate(_name, _amount);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 2){
          //2 retrieve amount from sharebee_public to sharebee_private,
          consolidateToPrivate(_name, _amount);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 3){
          //3 is mint amount in sharebee_private,
          mint(_amount);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 4){
          //4 is burn amount in sharebee_private
          burn(_amount);
          resetAdminAction();
          return true;
        }
        else{
          resetAdminAction();
          return false;
        }
      }
    }
    else{
      // if request is valid has nothing in common with current request OR previous request was fulfilled
      //drop previous request and replace with new one
      adminChangeRequest.amount = _amount;
      adminChangeRequest.acceptingOwners = [msg.sender];
      adminChangeRequest._type = _type;
      adminChangeRequest.name = _name;
      return true;
    }
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

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return sharebeeStorage.getUint(keccak256("user.balance.SHBX",_owner));
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
        sharebeeStorage.setUint(keccak256("user.balance.SHBX", _to), _destBalance);
        sharebeeStorage.setUint(keccak256("user.balance.SHBX", msg.sender), _senderBalance);

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
    sharebeeStorage.setUint(keccak256("user.balance.SHBX", _to), _destBalance);
    sharebeeStorage.setUint(keccak256("user.balance.SHBX", msg.sender), _senderBalance);
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
