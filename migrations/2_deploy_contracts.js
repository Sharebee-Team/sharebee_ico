var SharebeeToken = artifacts.require("./SharebeeToken.sol");
var sbStorage = artifacts.require("./Storage.sol");
var Storage_Interface = artifacts.require("./Storage_Interface.sol");

module.exports = function(deployer) {
  deployer.deploy(sbStorage);
  deployer.deploy(SharebeeToken);
};
