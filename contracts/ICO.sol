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

contract ICO{
  using SafeMath for uint256;

  //contracts
  StorageV3 sharebeeStorage = StorageV3(0);

  //contants
  address private fundWallet;
  string private constant publicBalanceString = "sharebee_public.balance.SHBX";


  //EVENTS
  event Buy(address indexed from, address indexed to, uint value, bytes indexed data);

  //MODIFIERS
  modifier isOwner(){
    require(sharebeeStorage.getAddress(keccak256("owner.address",msg.sender)) != 0x0);
    _;
  }

  modifier isAcceptedAmount() {
    require(msg.value > 1000 wei && msg.value < 5 ether);
    _;
  }

  //Constructor
  function ICO(address _storageAddress) public{
    sharebeeStorage = StorageV3(_storageAddress);
    fundWallet = sharebeeStorage.getAddress(keccak256("fund.name", "fundWallet"));
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

  function forwardFunds() private{
    //forwards funds to specified ether wallet upon contribution
    fundWallet.transfer(msg.value);
  }

  function balanceOfSharebeePublic() public constant returns (uint256 balance) {
    return sharebeeStorage.getUint(keccak256(publicBalanceString));
  }

  function balanceOf(address _owner) public constant returns (uint256 balance) {
    return sharebeeStorage.getUint(keccak256("user.balance.SHBX",_owner));
  }

  // Function that is called when a user or another contract wants to buy funds .
  function buy(address _to, uint _value, bytes _data, string _custom_fallback) public isAcceptedAmount payable returns (bool success) {

    if(isContract(_to)) {
        uint256 _sharebeeBalance = balanceOfSharebeePublic();
        uint256 _destBalance = balanceOf(_to);
        if (_sharebeeBalance < _value) revert();
        //compute transaction result
        _sharebeeBalance = _sharebeeBalance.sub(_value);
        _destBalance = _destBalance.add(_value);
        assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));

        //set values
        sharebeeStorage.setUint(keccak256("user.balance.SHBX", _to), _destBalance);
        sharebeeStorage.setUint(keccak256(publicBalanceString), _sharebeeBalance);
        forwardFunds();
        Buy(msg.sender, _to, _value, _data);
        return true;
    }
    else {
      return true;
        //return buyToAddress(_to, _value, _data);
    }
  }
   // Function that is called when a user or another contract wants to buy funds .
  function buy(address _to, uint _value, bytes _data) public payable returns (bool success) {
    if(isContract(_to)) {
        return buyToContract(_to, _value, _data);
    }
    else {
        return buyToAddress(_to, _value, _data);
    }
  }
  // Standard function buy similar to ERC20 buy with no _data .
  function buy(address _to, uint _value) public payable returns (bool success) {
    //standard function buy similar to ERC20 buy with no _data
    bytes memory empty;
    if(isContract(_to)) {
        return buyToContract(_to, _value, empty);
    }
    else {
        return buyToAddress(_to, _value, empty);
    }
  }

  //function that is called when transaction target is an address
  function buyToAddress(address _to, uint _value, bytes _data) private isAcceptedAmount returns (bool success) {
    uint256 _sharebeeBalance = balanceOfSharebeePublic();
    uint256 _destBalance = balanceOf(_to);
    if (_sharebeeBalance < _value) revert();
    //compute transaction result
    _sharebeeBalance = _sharebeeBalance.sub(_value);
    _destBalance = _destBalance.add(_value);
    //set values
    sharebeeStorage.setUint(keccak256("user.balance.SHBX", _to), _destBalance);
    sharebeeStorage.setUint(keccak256(publicBalanceString), _sharebeeBalance);
    forwardFunds();
    Buy(msg.sender, _to, _value, _data);
    return true;
  }

  //function that is called when transaction target is a contract
  function buyToContract(address _to, uint _value, bytes _data) private isAcceptedAmount returns (bool success) {
    uint256 _sharebeeBalance = balanceOfSharebeePublic();
    uint256 _destBalance = balanceOf(_to);
    if (_sharebeeBalance < _value) revert();
    //compute transaction result
    _sharebeeBalance = _sharebeeBalance.sub(_value);
    _destBalance = _destBalance.add(_value);

    ContractReceiver receiver = ContractReceiver(_to);
    receiver.tokenFallback(msg.sender, _value, _data);

    sharebeeStorage.setUint(keccak256("user.balance.SHBX", _to), _destBalance);
    sharebeeStorage.setUint(keccak256(publicBalanceString), _sharebeeBalance);
    forwardFunds();
    Buy(msg.sender, _to, _value, _data);
    return true;
  }
}
