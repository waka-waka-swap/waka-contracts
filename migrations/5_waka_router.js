var WakaSwapRouter02 = artifacts.require('WakaSwapRouter02');
var MockWakaSwapFactory = artifacts.require('MockWakaSwapFactory');
var MockWETH9 = artifacts.require('MockWETH9');

module.exports = async function (deployer) {
  const factory = await MockWakaSwapFactory.deployed();
  const weth9 = await MockWETH9.deployed();
  await deployer.deploy(WakaSwapRouter02, factory.address, weth9.address);
};
