pragma solidity ^0.4.4;

contract StorageV2 {
  address internal creator;
  uint256 public constant totalSupply = 10000;
  uint internal creatorAddCount = 0;
  uint internal ownerCount = 1;
  mapping(address => bool) owners;
  address[] public accepted;                                //accepted addresses to execute api transactions
  mapping(address => uint256) balances;
  uint public constant ownerAgreeThreshold = 2;             //threshold to execute consensus actions
  //consensus admin request
  AdminChangeRequest public adminChangeRequest;


  // STRUCTS
  struct AdminChangeRequest{
    address addr;
    address[] acceptingOwners;
    uint _type;
    //  0 is none, 1 is add new accepted address, 2 is remove accepted address, 3 is add owner, 4 is remove owner
  }

  // MODIFIERS

  modifier isOwner(){
      require(owners[msg.sender]);
      _;
  }


  modifier isCreator(){
    require(creator == msg.sender);
    _;
  }

  modifier isAcceptedAddress(){
    require(accepted.length > 0);
    bool isAccepted = false;
    address[] memory acc = accepted;
    for(uint i = 0; i < acc.length; i++){
      if(msg.sender == acc[i]){
        isAccepted = true;
      }
    }
    require(isAccepted);
    _;
  }


  // ADMIN HELPER FUNCTIONS

  //fund wallet actions
  function addOwner(address addr) public isCreator returns(bool){
    require(creatorAddCount < 2 && !owners[addr]); //fund wallet must add the first two owners
    owners[addr] = true;
    creatorAddCount++;
    ownerCount++;
    return true;
  }

  function removeAcceptedAddress(address addr) internal returns(bool){
    require(accepted.length > 0);
    bool found = false;
    address[] memory acc = accepted;
    for(uint i = 0; i < acc.length - 1; i++){
      if(acc[i] != addr && !found){
        continue;
      }
      else if(acc[i] == addr){
        found = true;
      }

      if(found){
        acc[i] = acc[i+1];
      }
    }
    delete acc[accepted.length - 1];
    acc.length--;
    accepted = acc;
    return true;
  }

  // ADMIN FUNCTIONS

  //NEEDS TO STILL BE OPTIMIZED IN TERMS OF OPCODES (right now its reading and storing from storage a lot)
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
          // add new accepted service contract address
          accepted.push(adminChangeRequest.addr);
          return true;
        }
        else if(adminChangeRequest._type == 2 && ownerCount == 3){
          // remove current accepted service contract address (NULLIFY)
          removeAcceptedAddress(adminChangeRequest.addr);
        }
        else if(adminChangeRequest._type == 3 && ownerCount == 2 && creatorAddCount == 2){
          // add new owner
          owners[adminChangeRequest.addr] = true;
          ownerCount++;
        }
        else if(adminChangeRequest._type == 4 && ownerCount == 3){
          // remove owner
          owners[adminChangeRequest.addr] = false;
          ownerCount--;
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
      // if request has nothing in common with current request OR previous request was fulfilled
      //drop previous request and replace with new one
      adminChangeRequest.addr = addr;
      adminChangeRequest.acceptingOwners = [msg.sender];
      adminChangeRequest._type = _type;
      return true;
    }
  }

  // SERVICE CONTRACT FUNCTIONS
  function totalSupply() public constant returns (uint256) {
    return totalSupply;
  }

  function getBalance(address addr) public constant returns(uint256){
    return balances[addr];
  }

  function setBalance(address addr, uint256 amount) public isAcceptedAddress returns(bool){
    balances[addr] = amount;
    return true;
  }

  // CONSTRUCTOR
  function StorageV2() public{
    creator = msg.sender;
    balances[msg.sender] = totalSupply;
  }




}
