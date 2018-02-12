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

burn token functionality

QUESTION
add extra security -- whitelist mapping?
add distinction from pure utility token and exchange token?
define phases caps and discounts?





*/


contract SharebeeTokenV2 is StandardToken {

  //token properties
  string public constant name = "Sharebee Token";           //Token name
  uint8 public constant decimals = 18;                      //number of decimals to show
  string public constant symbol = "SHBT";                   //token symbol
  uint256 public constant overall_supply = 100000;         //total supply of tokens
  uint256 public constant exchange_supply = 80000;          //Initial supply of exchange tokens
  uint256 public constant utility_supply = 20000;           //Initial supply of utility tokens
  Phase[4] public phases;                                   //ICO phases
  //mapping(address => uint256) public utility_balances;      //
  uint public constant ownerAgreeThreshold = 2;             //threshold to execute consensus actions


  uint public ownerCount = 1;
  uint public fundWalletOwnerAdds = 0;




  //consensus admin request
  AdminChangeRequest public adminChangeRequest;

  // admin consensus controlled state variables
  mapping (address => bool) public owners;                  //Identifiys certain addresses as owners
  address public fundWallet;                                //wallet that has all sharebee tokens
  address public etherWallet;                               //wallet that can withdraw ether from contract
  bool public mintable = false;                             //signal token is can mint
  bool public tradeable = false;                            // signal that SHBT is running
  bool public halted = false;                               // halt buying due to emergency,


  //STRUCTS

  struct AdminChangeRequest{//
    address addr;
    address[] acceptingOwners;
    uint _type;
    //  0 is none, 1 is Fund Wallet change, 2 is add owner, 3 is remove owner, 4 is change etherWallet
    // 5 is mintable false, 6 is mintable true, 7 is tradeable false, 8 is tradeable true, 9 is halted false, 10 is halted true
  }

  // Description for each phase
  struct Phase {
      uint256 tokenStart;
      uint256 tokenEnd;
      uint256 bonusDenominator;
  }

  //EVENTS
  event Mint(address indexed to, uint256 amount);
  event BuyToken(address indexed to, uint256 _wei, uint256 _shbt, uint timeOfBuy);
  event AddedOwner(address indexed who);
  event RemovedOwner(address indexed who);
  event ChangedFundWallet(address indexed to);
  event ChangedEtherWallet(address indexed to);
  event ToggledMintable(bool to);
  event ToggledTradeable(bool to);
  event ToggledHalted(bool to);

  //MODIFIERS

  modifier isTradeable { // exempt fundWallet to allow dev allocations
      require(tradeable || msg.sender == fundWallet );
      _;
  }
  modifier ownersAreSet(){
    require(ownerCount ==3);
    _;
  }
  modifier isOwner(){
      require(owners[msg.sender]);
      _;
  }
  modifier isFundWallet(){
    require(msg.sender == fundWallet);
    _;
  }
  modifier isEtherWallet(){
    require(msg.sender == etherWallet);
    _;
  }
  modifier isMintable(){
    require(mintable);
    _;
  }

  //fund wallet actions
  function addOwner(address addr) public isFundWallet returns(bool){
    require(fundWalletOwnerAdds < 2 && !owners[addr]); //fund wallet can add the first two owners
    owners[addr] = true;
    AddedOwner(addr);
    fundWalletOwnerAdds++;
    ownerCount++;
    return true;
  }



  //Test Functions ********************************REMOVE BEFORE DEPLOYMENT************************
  function getOwner(address addr) public constant returns(bool){
    if(owners[addr]){
      return true;
    }
    else{
      return false;
    }
  }
  function getFundWallet() public constant returns(address){
    return fundWallet;
  }
  function getOwnerCount() public constant returns(uint256){
    return ownerCount;
  }
  function getEtherWallet() public constant returns(address){
    return etherWallet;
  }
  function getCurrentAdminRequest() public constant returns(address, address[], uint){
    return (adminChangeRequest.addr, adminChangeRequest.acceptingOwners, adminChangeRequest._type);
  }
  function getMintable() public constant returns(bool){
    return mintable;
  }
  //End Test Functions




  // OWNER Functions
  function mint(uint256 _amount) isOwner isMintable public returns (bool) {
      //type 1 is exchangable balance, type 2 is utility balance
      totalSupply_ = totalSupply_.add(_amount);
      //if(_type == 1){
        balances[fundWallet] = balances[fundWallet].add(_amount);
      /* }
      else if(_type == 2){
        utility_balances[fundWallet] = utility_balances[fundWallet].add(_amount);
      } */

      Mint(fundWallet, _amount);
      Transfer(address(0), fundWallet, _amount);
      return true;
  }

  // OWNER CONSENSUS FUNCTIONS ------------------------------------------------------------------

  function adminChangeAction(address addr, uint256 _type) public isOwner returns(bool){
    if(adminChangeRequest.addr == addr && (addr != address(0) || adminChangeRequest._type >= 5) && adminChangeRequest._type == _type && adminChangeRequest._type != 0){
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
        else if(adminChangeRequest._type == 1 && ownerCount == 3){
          //fund wallet changes
          uint256 amount = balances[fundWallet];
          balances[fundWallet].sub(amount);
          balances[adminChangeRequest.addr].add(amount);
          /* utility_balances[fundWallet].sub(amount);
          utility_balances[adminChangeRequest.addr].add(amount); */
          fundWallet = adminChangeRequest.addr;
          ChangedFundWallet(adminChangeRequest.addr);

        }
        else if(adminChangeRequest._type == 2 && ownerCount < 3 && !owners[adminChangeRequest.addr]){
          //add owner
          owners[adminChangeRequest.addr] = true;
          AddedOwner(adminChangeRequest.addr);
          ownerCount++;
        }
        else if(adminChangeRequest._type == 3 && ownerCount == 3 && owners[adminChangeRequest.addr]){
          //remove owner
          owners[adminChangeRequest.addr] = false;
          RemovedOwner(adminChangeRequest.addr);
          ownerCount--;
        }
        else if(adminChangeRequest._type == 4 && ownerCount == 3){
          //ether wallet change
          etherWallet = adminChangeRequest.addr;
          ChangedFundWallet(adminChangeRequest.addr);
        }
        else if(adminChangeRequest._type == 5 && ownerCount == 3){ // NOTE: all types >= 5 are switches and therefore dont need addresses
          //mintable switch
          mintable = false;
          ToggledMintable(false);
        }
        else if(adminChangeRequest._type == 6 && ownerCount == 3){
          //mintable switch
          mintable = true;
          ToggledMintable(true);
        }
        else if(adminChangeRequest._type == 7 && ownerCount == 3){
          //tradable switch
          tradeable = false;
          ToggledTradeable(false);
        }
        else if(adminChangeRequest._type == 8 && ownerCount == 3){
          //tradable switch
          tradeable = true;
          ToggledTradeable(true);
        }
        else if(adminChangeRequest._type == 9 && ownerCount == 3){
          //halted switch
          halted = false;
          ToggledHalted(false);
        }
        else if(adminChangeRequest._type == 10 && ownerCount == 3){
          //halted switch
          halted = true;
          ToggledHalted(true);
        }
        else{
          return false;
        }

        //remove admin change request after execution
        adminChangeRequest._type = 0;
        adminChangeRequest.addr = address(0);
      }
    }
    else{
      //drop previous request and replace with new one
      adminChangeRequest.addr = addr;
      adminChangeRequest.acceptingOwners = [msg.sender];
      adminChangeRequest._type = _type;
      return true;
    }
  }



  //HELPER INTERNAL FUNCTIONS---------------------------------------------------------------------------------

  function getTokensWithBonus(uint256 _contribution, uint256 _USDToWei ) internal constant returns(uint256){
    //contribution is in wei
    uint256 tokenAmount = _contribution.div(_USDToWei).mul(10);
    uint256 bonusAmount = getBonus(tokenAmount);
    return tokenAmount.add(bonusAmount);
  }

  function getBonus(uint256 _tokenAmount) internal constant returns (uint256){
    if(balances[fundWallet] == 0){
      return 0;
    }
    uint256 amountTokensSold = exchange_supply - balances[fundWallet];
    for(uint i = 0; i < phases.length; i++){
      if(amountTokensSold >= phases[i].tokenStart && amountTokensSold < phases[i].tokenEnd){
        if(phases[i].bonusDenominator == 0){
          return 0;
        }
        return _tokenAmount.div(phases[i].bonusDenominator);
      }
    }
  }


  //payable functions

  //fallback
  function () external payable{
    buyTokens(msg.sender);
  }

  function buyTokens(address _for) public payable {
    require(!halted);
    require(_for != address(0));
    require(msg.value > 0);
    //GET REAL TIME CONVERSION!
    //uint256 _USDToWei = 1228908 * 10**9;
    uint256 _USDToWei = 1000;
    uint256 tokenAmount = getTokensWithBonus(msg.value, _USDToWei);


    require(tokenAmount <= balances[fundWallet]);
    balances[_for] = balances[_for].add(tokenAmount);
    balances[fundWallet] = balances[fundWallet].sub(tokenAmount);
    BuyToken(_for, msg.value, tokenAmount, now);
    forwardFunds();
  }


  /**
  * @dev Contract constructor -- sets the hard cap and initalizes all tokens with contract creator
  */
  function SharebeeTokenV2() public {
    fundWallet = msg.sender;
    etherWallet = msg.sender;
    owners[msg.sender] = true;
    totalSupply_ = overall_supply;
    balances[fundWallet] = overall_supply;
    //utility_balances[fundWallet] = utility_supply;

    //admin changes
    address[] memory adminChangeArr;
    adminChangeRequest = AdminChangeRequest({addr: address(0), acceptingOwners:adminChangeArr , _type: 0});


    //Phases
    phases[0].tokenStart = 0;
    phases[0].tokenEnd = 1000;
    phases[0].bonusDenominator = 4;

    phases[1].tokenStart = 1001;
    phases[1].tokenEnd = 2000;
    phases[1].bonusDenominator = 5;

    phases[2].tokenStart = 2001;
    phases[2].tokenEnd = 3000;
    phases[2].bonusDenominator = 10;

    phases[3].tokenStart = 3001;
    phases[3].tokenEnd = exchange_supply;
    phases[3].bonusDenominator = 0;
  }

  function forwardFunds() internal{
    //forwards funds to specified ehter wallet upon contribution
    require(etherWallet != address(0));
    etherWallet.transfer(msg.value);
  }

  // prevent transfers until trading allowed
  function transfer(address _to, uint256 _value) public isTradeable returns (bool success) {
      return super.transfer(_to, _value);
  }
  function transferFrom(address _from, address _to, uint256 _value) public isTradeable returns (bool success) {
      return super.transferFrom(_from, _to, _value);
  }
}
