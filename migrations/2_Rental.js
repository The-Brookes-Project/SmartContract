const Rental = artifacts.require("Rental");

module.exports = function (deployer) {
  deployer.deploy(Rental, 5);
};