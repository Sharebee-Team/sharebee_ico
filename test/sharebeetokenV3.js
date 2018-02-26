var SharebeeToken = artifacts.require("StorageV2_Service1.sol");
var SbStorage = artifacts.require("StorageV2.sol");


contract('SharebeeToken', function([owner,owner2, owner3]) {

  let sharebeeToken;
  let sbStorage;


  beforeEach('setup contracts for each test', async function(){
    sharebeeToken = await SharebeeToken.new(owner);
    sbStorage = await SbStorage.new(owner);
  });


  it("Contracts have a creator", async function(){
    assert.equal(await sharebeeToken.owner(), owner, "token owner incorrect");
    assert.equal(await sbStorage.owner(), owner, "sotrage owner incorrect");
  });


  it("is able to set storage address for Service contract", async function(){
    await sharebeeToken.setStorageAddress(sbStorage.address, {from: owner});
    let addr = await sharebeeToken.getStorageAddress.call({from: owner});
    assert.equal(addr, sbStorage.address, "Sharebee Token address wasnt set correctly");
  });


  it("is able to add and remove accepted addresses to SbStorage", async function(){
    await sbStorage.addOwner(owner2, {from: owner});
    await sbStorage.addOwner(owner3, {from: owner});
    await sbStorage.adminChangeAction(sharebeeToken.address,1, {from: owner});
    let addresses = await sbStorage.getAcceptedAddresses.call({from: owner});
    assert(!addresses.includes(sharebeeToken.address),"added address without multi signature");

    await sbStorage.adminChangeAction(sharebeeToken.address,1, {from: owner});
    let doubleAdd = await sbStorage.getAcceptedAddresses.call({from: owner});
    assert(!addresses.includes(sharebeeToken.address), "Able to add address with double add! :( ")

    await sbStorage.adminChangeAction(sharebeeToken.address, 1, {from: owner2});
    let addressesAfterAdd = await sbStorage.getAcceptedAddresses.call({from: owner});
    assert(addressesAfterAdd.includes(sharebeeToken.address),"Did not add with multisignature admin request");


    await sbStorage.adminChangeAction(sharebeeToken.address, 2, {from:owner});
    await sbStorage.adminChangeAction(sharebeeToken.address, 2, {from: owner2});
    let removeAddress = await sbStorage.getAcceptedAddresses.call({from: owner});
    console.log("Can you remove addresses with multi signature?", !removeAddress.includes(sharebeeToken.address));
    assert(!removeAddress.includes(sharebeeToken.address));

  });

});
