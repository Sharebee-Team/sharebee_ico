var SharebeeToken = artifacts.require("SharebeeTokenV2.sol");

contract('SharebeeToken', function([fundWallet, owner1 , owner2, owner3]) {
  let sharebeeToken;

  beforeEach('setup contracts for each test', async function(){
    sharebeeToken = await SharebeeToken.new(fundWallet);
  });


  it("Able to add two owners from fund wallet", async function(){
    await sharebeeToken.addOwner(owner1);
    let a1 = await sharebeeToken.getOwner.call(owner1)
    console.log("-------------------------" ,a1);
    assert(a1, "Couldnt add 1st owner");
    //test adding same owner twice
    sharebeeToken.addOwner(owner1)
      .then((res) => {
        //console.log("-------------------------" ,res);
        assert(false, "added owner twice!! ");
      })
      .catch((res) =>{
        //console.log("-------------------------" ,res);
        assert(true);
      })

    await sharebeeToken.addOwner(owner2);
    let a2 = await sharebeeToken.getOwner.call(owner2)
    assert(a2, "Couldnt add 2nd owner");

    await sharebeeToken.addOwner(owner3)
      .then((res)=>{
        assert(false, "added third owner");
      })
      .catch((res)=>{
        assert(true);
      });
  });

  /*
    cases tested:
      adding owner without consensus (only 1 request)
      adding owner twice from the same sender
      adding owner with consensus (2 requests)
    cases not tested:
      adding owner when 3 owners already exist
      adding address that is already owner
  */
  it("Able to add owner with owner consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    console.log("b0--------------------------------------------------------")
    await sharebeeToken.adminChangeAction(owner2, 2 , {from: owner1});
    let added = await sharebeeToken.getOwner.call(owner2);
    console.log("can you add with only 1 request?", added)
    assert(!added, "added with only 1 call");
    let doubleAdd = await sharebeeToken.adminChangeAction.call(owner2,2, {from:owner1});
    console.log("can you double add?", doubleAdd);
    assert(!doubleAdd, "was able to double add ");
    await sharebeeToken.adminChangeAction(owner2, 2, {from: fundWallet});
    let shouldBeAdded = await sharebeeToken.getOwner.call(owner2);
    console.log("can you add after threshold reached?", shouldBeAdded);
    assert(shouldBeAdded, "Wasnt added correctly");
  });

  /*
    cases tested:
      removing owner without consensus (only 1 request)
      removing owner twice from the same sender
      removing owner with consensus (2 requests)
    cases not tested:
      removing owner when only two owners exist
      removing non-owner address
  */
  it("Able to remove owner with owner consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(owner2,3,{from:owner1});
    let notRemoved = await sharebeeToken.getOwner.call(owner2);
    console.log("you CANT remove after 1 request?", notRemoved);
    assert(notRemoved, "removed owner after only 1 call");
    let doubleRemove = await sharebeeToken.adminChangeAction.call(owner2, 3,{from: owner1});
    console.log("can you double remove?", doubleRemove);
    assert(!doubleRemove, "was able to double remove someone");
    let preRemoveOwnerCount = await sharebeeToken.getOwnerCount();
    console.log("Owner count before remove", preRemoveOwnerCount.toString())
    await sharebeeToken.adminChangeAction(owner2,3,{from: fundWallet});
    let stillOwner = await sharebeeToken.getOwner.call(owner2);
    console.log("Is the person still owner after removal threshold reached?", stillOwner);
    assert(!stillOwner, "didnt remove owner 2 correctly");
    let postRemoveOwnerCount = await sharebeeToken.getOwnerCount();
    console.log("Owner count after remove", postRemoveOwnerCount.toString())
  });

  /*
    cases tested:
      changing fund wallet address without consensus (only 1 request)
      changing fund wallet when only two owners exist
      changing fund wallet with consensus
    cases not tested:
      requesting to change fund wallet twice from same sender
      changing fund wallet to same address?
  */
  it("Able to change fund wallet with consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    let startFundWallet = await sharebeeToken.getFundWallet();
    console.log("whats the starting fund wallet?",startFundWallet);
    await sharebeeToken.adminChangeAction(owner3,1,{from:fundWallet});
    let midFundWallet = await sharebeeToken.getFundWallet();
    console.log("should be the same as starting address",midFundWallet);
    assert.equal(startFundWallet, midFundWallet, "changed fundwallet address after 1 request");
    let fundChangeWithOnly2Owners = await sharebeeToken.adminChangeAction.call(owner3,1,{from: owner1});
    console.log("can fund wallet be changed with only two owners?", fundChangeWithOnly2Owners);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(owner3, 1, {from: owner2});

    let finalFundWallet = await sharebeeToken.getFundWallet();
    console.log("should be a new address", finalFundWallet);
    assert.notEqual(startFundWallet, finalFundWallet, "Didnt change fund wallet");
  });

  /*
    TODO:
      change ether wallet with consensus
      change mintable with consensus
      minting tokens
      change tradeable with CONSENSUS
      change halted with consensus

      buy tokens (check restrictions when not tradeable/when halted)

      withdraw using ether wallet

  */




});
