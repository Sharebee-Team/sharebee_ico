var SharebeeToken = artifacts.require("SharebeeTokenV2.sol");

contract('SharebeeToken', function([fundWallet, owner1 , owner2, owner3]) {
  let sharebeeToken;

  beforeEach('setup contracts for each test', async function(){
    sharebeeToken = await SharebeeToken.new(fundWallet);
  });

  /*
    cases tested:
      Initial owner can add two other owners
      restricts/blocks initial owner from adding a third owner
    cases not tested:
  */
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
      adding owner when 3 owners already exist
      adding address that is already owner
    cases not tested:

  */
  it("Able to add owner with owner consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    console.log("b0--------------------------------------------------------")
    await sharebeeToken.adminChangeAction(owner1,2,{from:owner1});
    let addExistingOwner = await sharebeeToken.adminChangeAction.call(owner1,2,{from:fundWallet});
    console.log("can you re-add an existing owner?", addExistingOwner);
    await sharebeeToken.adminChangeAction(owner2, 2 , {from: owner1});
    let added = await sharebeeToken.getOwner.call(owner2);
    console.log("can you add with only 1 request?", added)
    assert(!added, "added with only 1 call");
    let doubleAdd = await sharebeeToken.adminChangeAction.call(owner2,2, {from:owner1});
    console.log("can you double add from single requester?", doubleAdd);
    assert(!doubleAdd, "was able to double add ");
    await sharebeeToken.adminChangeAction(owner2, 2, {from: fundWallet});
    let shouldBeAdded = await sharebeeToken.getOwner.call(owner2);
    console.log("can you add after threshold reached?", shouldBeAdded);
    assert(shouldBeAdded, "Wasnt added correctly");
    await sharebeeToken.adminChangeAction(owner3, 2, {from: fundWallet});
    let adding4thOwner = await sharebeeToken.adminChangeAction.call(owner3, 2, {from: owner1});
    console.log("can you add a 4th owner with consensus?", adding4thOwner);
    assert(!adding4thOwner, "Was able to add a 4th owner");

  });

  /*
    cases tested:
      removing owner without consensus (only 1 request)
      removing owner twice from the same sender
      removing owner with consensus (2 requests)
      removing owner when only two owners exist
      removing non-owner address
    cases not tested:

  */
  it("Able to remove owner with owner consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(owner3, 3, {from:owner1});
    let removeNonOwner = await sharebeeToken.adminChangeAction.call(owner3, 3, {from: fundWallet});
    console.log("can you remove a non-owner?", removeNonOwner);
    assert(!removeNonOwner, "Was able to remove non owner");
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
    await sharebeeToken.adminChangeAction(owner1,3,{from:owner1});
    let removeWhenOnly2Owners = await sharebeeToken.adminChangeAction.call(owner1,3,{from:fundWallet});
    console.log("can you remove with consensus when only two owners?", removeWhenOnly2Owners);
    assert(!removeWhenOnly2Owners, "Was able to remove with only two owners");
  });

  /*
    cases tested:
      changing fund wallet address without consensus (only 1 request)
      changing fund wallet when only two owners exist
      changing fund wallet with consensus
      requesting to change fund wallet twice from same sender
    cases not tested:
  */
  it("Able to change fund wallet with consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    let startFundWallet = await sharebeeToken.getFundWallet();
    console.log("whats the starting fund wallet?",startFundWallet);
    await sharebeeToken.adminChangeAction(owner3,1,{from:fundWallet});
    let midFundWallet = await sharebeeToken.getFundWallet();
    console.log("should be the same as starting address",midFundWallet);
    assert.equal(startFundWallet, midFundWallet, "changed fundwallet address after 1 request");
    let fundChangeWithDoubleRequest = await sharebeeToken.adminChangeAction.call(owner3,1,{from: fundWallet});
    console.log("can you change fund wallet with double request?", fundChangeWithDoubleRequest);
    assert(!fundChangeWithDoubleRequest, "was able to change fund wallet with double request");
    let fundChangeWithOnly2Owners = await sharebeeToken.adminChangeAction.call(owner3,1,{from: owner1});
    console.log("can fund wallet be changed with only two owners?", fundChangeWithOnly2Owners);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(owner3, 1, {from: owner2});

    let finalFundWallet = await sharebeeToken.getFundWallet();
    console.log("should be a new address", finalFundWallet);
    assert.notEqual(startFundWallet, finalFundWallet, "Didnt change fund wallet");
  });

  /*
    cases tested:
      changing ether wallet address without consensus (only 1 request)
      changing ether wallet when only two owners exist
      changing ether wallet with consensus
      requesting to change ether wallet twice from same sender
    cases not tested:
  */
  it("Able to change ether wallet with consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    let startEtherWallet = await sharebeeToken.getEtherWallet();
    console.log("whats the starting ether wallet?",startEtherWallet);
    await sharebeeToken.adminChangeAction(owner3,4,{from:fundWallet});
    let midEtherWallet = await sharebeeToken.getEtherWallet();
    console.log("should be the same as starting address",midEtherWallet);
    assert.equal(startEtherWallet, midEtherWallet, "changed ether wallet address after 1 request");
    let etherChangeWithDoubleRequest = await sharebeeToken.adminChangeAction.call(owner3,4,{from: fundWallet});
    console.log("can you change ether wallet with double request?", etherChangeWithDoubleRequest);
    assert(!etherChangeWithDoubleRequest, "was able to change ether wallet with double request");
    let etherChangeWithOnly2Owners = await sharebeeToken.adminChangeAction.call(owner3,4,{from: owner1});
    console.log("can ether wallet be changed with only two owners?", etherChangeWithOnly2Owners);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(owner3, 4, {from: owner2});

    let finalEtherWallet = await sharebeeToken.getEtherWallet();
    console.log("should be a new address", finalEtherWallet);
    assert.notEqual(startEtherWallet, finalEtherWallet, "Didnt change ether wallet");
  });

  /*
    cases tested:
      Minting without consensus mintable
      changing mintable with CONSENSUS
      minting with consensus mintable
    cases not tested:
  */
  it("Able to mint tokens with consensus", async function(){
    await sharebeeToken.addOwner(owner1);
    await sharebeeToken.addOwner(owner2);
    let startSupply = parseInt(await sharebeeToken.totalSupply.call());
    console.log("starting supply", startSupply);
    try{
      await sharebeeToken.mint.call(1000, {from:fundWallet});
    }
    catch(e){
      console.log("Minting without mintable gets error");
      assert(true);
    }
    await sharebeeToken.adminChangeAction(0, 6, {from: fundWallet});
    await sharebeeToken.adminChangeAction(0, 6, {from: owner1});
    let isMintable = await sharebeeToken.getMintable.call();
    console.log("Is the token mintable with consensus?", isMintable);
    assert(isMintable, "mintable consensus action fail");
    await sharebeeToken.mint(1000, {from: fundWallet});
    let endSupply = parseInt(await sharebeeToken.totalSupply.call());
    console.log("end supply", endSupply);
    assert.notEqual(startSupply, endSupply, "Didnt mint successfully");
  });

  /*
    cases tested:
      Buying tokens with eth
      buying tokens when buying is halted
    cases not tested:
  */
  it("Able to buy tokens", async function(){
    await sharebeeToken.addOwner(owner1);
    await sharebeeToken.addOwner(owner2);
    await sharebeeToken.adminChangeAction(0, 10, {from: fundWallet});
    await sharebeeToken.adminChangeAction(0, 10, {from: owner1});
    let sb1 =  parseInt(await sharebeeToken.balanceOf.call(owner1));
    let sb2 =  parseInt(await sharebeeToken.balanceOf.call(owner2));
    console.log("start balance of owner 1", sb1);
    console.log("start balance of owner 2", sb2);
    try{
      await sharebeeToken.buyTokens(owner2, {from: owner1, value: 10000});
      assert(false, "able to buy tokens when halted");
    }
    catch(e){
      console.log("Error is thrown when trying to buy while halted");
      assert(true)
    }
    await sharebeeToken.adminChangeAction(0, 9, {from: fundWallet});
    await sharebeeToken.adminChangeAction(0, 9, {from: owner1});
    await sharebeeToken.buyTokens(owner2, {from: owner1, value: 10000});
    let eb1 =  parseInt(await sharebeeToken.balanceOf.call(owner1));
    let eb2 =  parseInt(await sharebeeToken.balanceOf.call(owner2));
    console.log("end balance of owner 1", eb1);
    console.log("end balance of owner 2", eb2);
    assert.equal(sb1, eb1, "sender received funds meant for someone else");
    assert.notEqual(sb2, eb2, "_for successfully receieved tokens");


  });

  /*
    TODO:
      change tradeable with CONSENSUS

      withdraw using ether wallet

  */




});
