/*

  Token:
    FEATURES:
      Mint
        double request from single user
        cant make change with less than 3 owners
        mint successfully
      Burn
        double request from single user
        cant make changes with less than 3 owners
        burn successfully
      Allocate to other sharebee account
        double request from single user
        cant make changes with less than 3 owners
        allocates successfully
      Retrieve from other sharebee account
        double request from single user
        cant make changes with less than 3 owners
        retrieves successfully
      transferToAddress
        successful
      transferToContract
        successful
        reverts when no transfer function -- need to build test contract

    ICO:
      FEATURES:
        successfully restricts to Accepted contribution amounts
        buyToAddress
          successful
        buyToContract
          successfull
          reverts when no transfer function -- build test contract
        forwardFunds
          successful


*/
const TOKEN = artifacts.require("Token.sol");
const ICO = artifacts.require("ICO.sol");
const SBSTORAGE = artifacts.require("StorageV3.sol");

contract('SbStorage', function([fundWallet, owner1 , owner2, owner3]) {
  let sbStorage;
  let ico;
  let token;

  beforeEach('setup contract for each test', async function () {
      sbStorage = await SBSTORAGE.new(fundWallet);
      ico = await ICO.new(sbStorage.address);
      token = await TOKEN.new(sbStorage.address);
  });

  //STORAGE TESTS
  /*Storage:
    FEATURES:
      add owner
        admin add owner only works after creator has added two owners
        admin add owner cant add if 3 owners exist\
        cant double add from single owner
        cant add already existent owner
      remove owner
        remove owner works
        cant double remove from single owner
        cant remove non-existent owner
      add accepted address
        double request from single owner
        must have 3 owners
        not successful if request with same address but different name
        add address works
        successfully accepts accepted addresses
      remove accepted address
        must have 3 owners
        double request from single owner
        remove address works
        successfully blocks non-accepted addresses
      adjust fund _fundWallet
        must have 3 owners
        double request from single user
        change works
*/

  it("Storage should have an owner", async function(){
    let ownerCheck = await sbStorage.checkOwner.call(fundWallet);
    console.log("Is creator of storage an owner?",ownerCheck);
    assert(ownerCheck, "Didnt initialize creator/owner correctly");
  });

  it("creator Initial adding owners", async function(){
    await sbStorage.addOwnerCreator(owner1, {from: fundWallet});
    try{
      await sbStorage.addOwnerCreator(owner1, {from: fundWallet});
      assert(false, "can add an existing owner again");
    }
    catch(e){
      assert(true);
      console.log("Reverts when trying to double add existing owner? true");
    }
    await sbStorage.addOwnerCreator(owner2, {from: fundWallet});
    try{
      await sbStorage.addOwnerCreator(owner3, {from: fundWallet});
      assert(false, "Can creator-add 3 owners");
    }
    catch(e){
      assert(true);
      console.log("Reverts when trying to add 3rd owner from creator? true");
    }
  });

  it("Consensus adding/removing owners", async function(){
    await sbStorage.addOwnerCreator(owner1, {from: fundWallet});
    let owner1success = await sbStorage.checkOwner(owner1);
    console.log("successful creator add1?", owner1success);

    //consensus add before creator is done adding
    await sbStorage.adminChangeAction(owner3, 3, "", {from: fundWallet});
    try{
      await sbStorage.adminChangeAction.call(owner3, 3, "", {from: owner1})
      assert(false, "can consensus add owner before creator is done with owner adds")
    }
    catch(e) {
      console.log("Reverts when trying to consensus-add before creator has added 2 owners? true");
      assert(true)
    }

    await sbStorage.addOwnerCreator(owner2, {from: fundWallet});
    let owner2success = await sbStorage.checkOwner(owner2);
    console.log("successful creator add?", owner2success);
    
    //have more than 3 owners
    await sbStorage.adminChangeAction(owner3, 3, "", {from: fundWallet});
    try{
      await sbStorage.adminChangeAction(owner3, 3, "", {from: owner1});
      assert(false, "you can you have more than 3 owners? true")
    }
    catch(e){
      console.log("you can you have more than 3 owners? false");
    }

  });



});
