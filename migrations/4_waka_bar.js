var WakaBar = artifacts.require('WakaBar');
var WakaToken = artifacts.require('WakaToken');

module.exports = async function (deployer, network) {
  if (network !== 'development' && network !== 'fantomtest') {
    return;
  }
  await deployer.deploy(WakaBar, (await WakaToken.deployed()).address);
};
