pragma solidity ^0.4.4;



/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

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

/******************************************************************************************************************************************************************
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20 {
  using SafeMath for uint256;

  mapping (address => mapping (address => uint256)) internal allowed;
  mapping(address => uint256) balances;
  uint256 totalSupply_;

  /**
  * @dev total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}




/*
THINGS to do:
add a fund wallet? see gron.sol

add extra security -- whitelist mapping? see gron.sol

short address attack? onlyPayloadSize gron.sol

multiple owners? at least 2


*/


contract Storage is StandardToken {

  address public owner;                                     //contract owner/admin
  string public constant name = "Sharebee Token";           //Token name
  uint8 public constant decimals = 18;                      //number of decimals to show
  string public constant symbol = "SHT";                    //token symbol
  uint256 public constant initial_supply = 100000;          //Initial supply of tokens
  address[] public accepted;                                //accepted addresses to execute api transactions
  
  /**
  * @dev modifier to check if sender is the creator of the contract
  */
  modifier isOwner(){
      require(msg.sender == owner);
      _;
  }

  /**
  * @dev Modifier to check if sender is on the list of accepted addresses (contracts in main platform)
  */
  modifier isAcceptedAddress(){
    require(accepted.length > 0);
    bool isAccepted = false;
    for(uint i = 0; i < accepted.length; i++){
      if(msg.sender == accepted[i]){
        isAccepted = true;
      }
    }
    require(isAccepted);
    _;
  }

  function getAcceptedAddresses() public constant isOwner returns(address[]){
    return accepted;
  }

  /**
  * @dev ONLY OWNER: adds an accepted address to execute transactions from
  */
  function addAcceptedAddress(address addr) public isOwner returns(bool){
    accepted.push(addr);
    return true;
  }

  /**
  * @dev ONLY OWNER: removes an accepted address to execute transactions from
  */
  function removeAcceptedAddress(address addr) public isOwner returns(bool){
    require(accepted.length > 0);
    bool found = false;
    for(uint i = 0; i < accepted.length - 1; i++){
      if(accepted[i] != addr && !found){
        continue;
      }
      else if(accepted[i] == addr){
        found = true;
      }

      if(found){
        accepted[i] = accepted[i+1];
      }
    }
    delete accepted[accepted.length - 1];
    accepted.length--;
    return true;
  }


  /**
  * @dev Contract constructor -- sets the hard cap and initalizes all tokens with contract creator test
  */
  function Storage() public {
    owner = msg.sender;
    totalSupply_ = initial_supply;
    balances[msg.sender] = initial_supply;
  }


  /**
  * @dev User buys tokens from an accepted address -- transfers tokens into their account
  */
  function acceptedBuyTokens(address _to, uint256 _value) public isAcceptedAddress returns (bool){

    require( _to != address(0));                        //Restricts transferring token to root address
    require(balances[owner] >= _value);                 //enforces source to have enough token to transfer
    require(balances[_to] + _value > balances[_to]);    //checks for overflows

    balances[owner] = balances[owner] - _value;
    balances[_to] = balances[_to] + _value;
    Transfer(owner, _to, _value);
    return true;
  }

  function acceptedUseTokens(address _from, uint256 _value) public isAcceptedAddress returns (bool){
    require(balances[_from] >= _value);
    require(balances[owner] + _value > balances[owner]);    //checks for overflows

    balances[owner] = balances[owner] + _value;
    balances[_from] = balances[_from] - _value;
    Transfer(_from, owner, _value);
    return true;
  }
}
