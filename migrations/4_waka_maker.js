var WakaMaker = artifacts.require('WakaMaker');
var MockWakaSwapFactory = artifacts.require('MockWakaSwapFactory');
var MockWETH9 = artifacts.require('MockWETH9');
var WakaToken = artifacts.require('WakaToken');
var WakaBar = artifacts.require('WakaBar');

module.exports = async function (deployer) {
  await deployer.deploy(MockWakaSwapFactory, "0x0000000000000000000000000000000000000000");
  await deployer.deploy(MockWETH9);
  const factory = await MockWakaSwapFactory.deployed();
  const weth9 = (await MockWETH9.deployed()).address;
  const waka = (await WakaToken.deployed()).address;
  const bar = (await WakaBar.deployed()).address;
  await deployer.deploy(WakaMaker, factory.address, bar, waka, weth9);
  factory.setFeeTo((await WakaMaker.deployed()).address);
};
