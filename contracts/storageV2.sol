pragma solidity ^0.4.4;

contract StorageV2 {
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
        else if(adminChangeRequest._type == 1){
          //
        }
        else if(adminChangeRequest._type == 2){

        }
        else if(adminChangeRequest._type == 3){

        }
        else if(adminChangeRequest._type == 4){

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




}
