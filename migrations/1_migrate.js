const MugenBet = artifacts.require("MugenBet");

module.exports = async function (deployer) {
  await deployer.deploy(MugenBet,'1000');
};
