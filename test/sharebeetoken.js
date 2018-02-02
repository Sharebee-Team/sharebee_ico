var SharebeeToken = artifacts.require("SharebeeToken.sol");
var SbStorage = artifacts.require("Storage.sol");
var Malicious = artifacts.require("Malicious.sol");
var FutureContract = artifacts.require("FutureContract.sol");


contract('SharebeeToken', function([owner, donor, attacker]) {

  let sharebeeToken;
  let sbStorage;
  let malicious;
  let futureContract;

  beforeEach('setup contracts for each test', async function(){
    sharebeeToken = await SharebeeToken.new(owner);
    sbStorage = await SbStorage.new(owner);
    malicious = await Malicious.new(attacker);
    futureContract = await FutureContract.new(owner);
  })

  it("Contracts have an owner", async function(){
    assert.equal(await sharebeeToken.owner(), owner);
    assert.equal(await sbStorage.owner(), owner);
  });

  it("is able to set storage address for Sharebee Token", async function(){
    await sharebeeToken.setStorageAddress(sbStorage.address, {from: owner});
    let addr = await sharebeeToken.getStorageAddress({from: owner});
    assert.equal(addr, sbStorage.address, "Sharebee Token address wasnt set correctly");
  });

  it("is able to add an accepted address to SbStorage", async function(){
    await sbStorage.addAcceptedAddress(sharebeeToken.address, {from: owner});
    let addresses = await sbStorage.getAcceptedAddresses({from: owner});
    assert(addresses.includes(sharebeeToken.address),"didnt add address to storage correctly");
    await sbStorage.removeAcceptedAddress(sharebeeToken.address, {from:owner});
    addresses = await sbStorage.getAcceptedAddresses({from:owner});
    assert(!addresses.includes(sharebeeToken.address),"didnt remove address from storage properly");
    await sbStorage.addAcceptedAddress(sharebeeToken.address, {from: owner});
    addresses = await sbStorage.getAcceptedAddresses({from: owner});
  });

  it("User can interact with Sharebee token contract to buy tokens though storage", async function(){
    await sbStorage.addAcceptedAddress(sharebeeToken.address, {from: owner});
    await sharebeeToken.setStorageAddress(sbStorage.address, {from: owner});
    let startAmount = (await sbStorage.balanceOf(donor)).toNumber();
    //console.log("START AMOUNT TEST", startAmount);
    await sharebeeToken.buy_ico(donor, {from: donor, value: 10});
    let endAmount = (await sbStorage.balanceOf(donor)).toNumber();
    //console.log("END AMOUNT TEST", endAmount);
    assert.isAbove(endAmount , startAmount, "Transaction didnt change balance");
  });

  it("Attacker contract is blocked", async function(){
    await malicious.setStorageAddress(sbStorage.address, {from: attacker});
    let startAmount = (await sbStorage.balanceOf(attacker)).toNumber();
    malicious.attack()
      .then(() => sbStorage.balanceOf(attacker))
      .then((endAmount) => {
        assert(false);
      })
      .catch((error)=> {
        //console.log(error);
        assert(true);
      });
  });

  it("Owner is able to invalidate contracts", async function(){
    await sbStorage.addAcceptedAddress(sharebeeToken.address, {from: owner});
    await sharebeeToken.setStorageAddress(sbStorage.address, {from: owner});
    await sbStorage.removeAcceptedAddress(sharebeeToken.address, {from: owner});

    let startAmount = (await sbStorage.balanceOf(donor)).toNumber();
    //console.log("START AMOUNT TEST", startAmount);
    sharebeeToken.buy_ico(donor, {from: donor, value: 10})
      .then(() => sbStorage.balanceOf(donor))
      .then((endAmount) => {
        assert(false);
      })
      .catch(error =>{
        //console.log(error)
        assert(true);
      });

  });

  it("Able to assign new contract to connect to storage", async function(){
    await sbStorage.addAcceptedAddress(sharebeeToken.address, {from: owner});
    await sharebeeToken.setStorageAddress(sbStorage.address, {from: owner});
    let startAmount = (await sbStorage.balanceOf(donor)).toNumber();

    await sharebeeToken.buy_ico(donor, {from: donor, value: 10});
    let endAmount = (await sbStorage.balanceOf(donor)).toNumber();
    assert.isAbove(endAmount , startAmount, "Transaction didnt change balance");

    await futureContract.setStorageAddress(sbStorage.address, {from: owner});
    await sbStorage.addAcceptedAddress(futureContract.address, {from: owner});
    startAmount = endAmount;
    console.log("START AMOUNT TEST", startAmount);
    await futureContract.some_use_functionality(donor, 10);
    endAmount = (await sbStorage.balanceOf(donor)).toNumber();
    console.log("END AMOUNT TEST", endAmount);
    assert.isAbove(startAmount, endAmount, "Using token didnt work");
  });



});
