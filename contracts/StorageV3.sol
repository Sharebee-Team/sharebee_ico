pragma solidity ^0.4.9;


contract StorageV3 {
  address public creator;
  uint internal creatorAddCount = 0;
  uint internal ownerCount = 1;
  mapping(bytes32 => address)    private addressStorage;
  mapping(bytes32 => string)     private stringStorage;
  mapping(bytes32 => uint256)    private uIntStorage;
  mapping(bytes32 => bool)       private boolStorage;
  uint public constant ownerAgreeThreshold = 2;             //threshold to execute consensus actions
  //consensus admin request
  AdminChangeRequest public adminChangeRequest;

  //TEST FUNCTIONS
  function checkOwner(address addr) public constant returns(bool){
    return addressStorage[keccak256("owner.address",addr)] != 0x0;
  }

  function checkAddress(address addr) public constant returns(bool){
    return addressStorage[keccak256("contract.address",addr)] != 0x0;
  }

  function checkFundWallet(address addr) public constant returns(bool){
    return addressStorage[keccak256("fund.address", addr)] == 0x0;
  }

  // CONSTRUCTOR
  function StorageV3(address _fundWallet) public{
    creator = msg.sender;
    addressStorage[keccak256("owner.address",msg.sender)] = msg.sender; // creator is the first owner
    addressStorage[keccak256("fund.address", _fundWallet)] = _fundWallet;
    addressStorage[keccak256("fund.name", "fundWallet")] = _fundWallet;
  }

  // STRUCTS
  struct AdminChangeRequest{
    address addr;
    string name;
    address[] acceptingOwners;
    uint _type;
    //  0 is none,
    //1 is add new accepted address,
    //2 is remove accepted address,
    //3 is add owner,
    //4 is remove owner
    //5 is changeFundWallet
  }

  // MODIFIERS
  modifier isOwner(){
      require(addressStorage[keccak256("owner.address",msg.sender)] != 0x0);
      _;
  }

  modifier isCreator(){
    require(creator == msg.sender);
    _;
  }

  modifier onlyAcceptedAddress(){
      // Make sure the access is permitted to only contracts in our Dapp
      require(addressStorage[keccak256("contract.address", msg.sender)] != 0x0);
      _;
  }

  // INTERNAL HELPER FUNCTIONS
  function removeOwner(address addr) private {
    require(ownerCount == 3 && addressStorage[keccak256("owner.address",addr)] != 0x0); //fund wallet must add the first two owners
    delete addressStorage[keccak256("owner.address",addr)];
    ownerCount--;
  }

  function addOwner(address addr) private {
    require(ownerCount == 2 && addressStorage[keccak256("owner.address",addr)] == 0x0 && creatorAddCount == 2); //fund wallet must add the first two owners
    addressStorage[keccak256("owner.address",addr)] = addr;
    ownerCount++;
  }

  function addAcceptedAddress(address addr, string name) private{
    require(ownerCount == 3 && addressStorage[keccak256("contract.address",addr)] == 0x0);
    addressStorage[keccak256("contract.address",addr)] = addr;
    addressStorage[keccak256("contract.name",name)] = addr;
  }

  function removeAcceptedAddress(address addr, string name) private{
    require(ownerCount == 3 && addressStorage[keccak256("contract.address",addr)] != 0x0);
    delete addressStorage[keccak256("contract.address",addr)];
    delete addressStorage[keccak256("contract.name",name)];
  }

  //FUND WALLET IS THE WALLET ADDRESS THAT ETHER WILL BE FORWARDED TO UPON ICO CONTRIBUTION
  function changeFundWallet(address addr) private{
    require(ownerCount == 3);
    address faddr = addressStorage[keccak256("fund.name", "fundWallet")];

    delete addressStorage[keccak256("fund.address", faddr)];
    addressStorage[keccak256("fund.address", addr)] = addr;
    addressStorage[keccak256("fund.name", "fundWallet")] = addr;
  }

  function resetAdminAction() private{
    //remove admin change request after execution
    adminChangeRequest._type = 0;
    adminChangeRequest.addr = address(0);
    adminChangeRequest.name = "";
  }

  //ADMIN AND CREATOR ACTIONS
  function addOwnerCreator(address addr) public isCreator returns(bool){
    require(creatorAddCount < 2 && addressStorage[keccak256("owner.address",addr)] == address(0));
    addressStorage[keccak256("owner.address",addr)] = addr;
    ownerCount++;
    creatorAddCount++;
    return true;
  }

  function adminChangeAction(address addr, uint256 _type, string _name) public isOwner returns(bool){
    if(adminChangeRequest.addr == addr && addr != address(0) && adminChangeRequest._type == _type &&
    keccak256(adminChangeRequest.name) == keccak256(_name) && adminChangeRequest._type != 0){
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
          // add new accepted service contract address
          addAcceptedAddress(adminChangeRequest.addr, _name);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 2){
          // remove current accepted service contract address (NULLIFY)
          removeAcceptedAddress(adminChangeRequest.addr, _name);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 3){
          // add new owner
          addOwner(adminChangeRequest.addr);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 4){
          // remove owner
          removeOwner(adminChangeRequest.addr);
          resetAdminAction();
          return true;
        }
        else if(adminChangeRequest._type == 5){
          //change fund wallet
          changeFundWallet(adminChangeRequest.addr);
          resetAdminAction();
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
      adminChangeRequest.addr = addr;
      adminChangeRequest.acceptingOwners = [msg.sender];
      adminChangeRequest._type = _type;
      adminChangeRequest.name = _name;
      return true;
    }
  }


  // GET METHODS

  /// @param _key The key for the record
  function getAddress(bytes32 _key) external constant returns (address) {
      return addressStorage[_key];
  }
  /// @param _key The key for the record
  function getUint(bytes32 _key) external constant returns (uint256) {
      return uIntStorage[_key];
  }
  /// @param _key The key for the record
  function getString(bytes32 _key) external constant returns (string) {
      return stringStorage[_key];
  }
  /// @param _key The key for the record
  function getBool(bytes32 _key) external constant returns (bool) {
      return boolStorage[_key];
  }

  //SET METHODS

  /// @param _key The key for the record
  function setAddress(bytes32 _key, address _value) onlyAcceptedAddress external {
    addressStorage[_key] = _value;
  }
  /// @param _key The key for the record
  function setUint(bytes32 _key, uint _value) onlyAcceptedAddress external {
    uIntStorage[_key] = _value;
  }
  /// @param _key The key for the record
  function setString(bytes32 _key, string _value) onlyAcceptedAddress external {
    stringStorage[_key] = _value;
  }
  /// @param _key The key for the record
  function setBool(bytes32 _key, bool _value) onlyAcceptedAddress external {
    boolStorage[_key] = _value;
  }

  // DELETE METHODS

  /// @param _key The key for the record
  function deleteAddress(bytes32 _key) onlyAcceptedAddress external {
    delete addressStorage[_key];
  }
  /// @param _key The key for the record
  function deleteUint(bytes32 _key) onlyAcceptedAddress external {
    delete uIntStorage[_key];
  }
  /// @param _key The key for the record
  function deleteString(bytes32 _key) onlyAcceptedAddress external {
    delete stringStorage[_key];
  }
  /// @param _key The key for the record
  function deleteBool(bytes32 _key) onlyAcceptedAddress external {
    delete boolStorage[_key];
  }



}
