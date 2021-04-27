var WakaBar = artifacts.require('WakaBar');
var WakaMaker = artifacts.require('WakaMaker');
var WakaSwapFactory = artifacts.require('WakaSwapFactory');
var WakaSwapRouter02 = artifacts.require('WakaSwapRouter02');

module.exports = async function (deployer) {
  const waka = "WAKA_TOKEN_ADDRESS";
  const feeToSetter = "FEE_TO_SETTER_ADDRESS";
  const wftm = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

  await deployer.deploy(WakaBar, waka);
  await deployer.deploy(WakaSwapFactory, feeToSetter);

  const bar = (await WakaBar.deployed()).address;
  const factory = await WakaSwapFactory.deployed();

  await deployer.deploy(WakaMaker, factory.address, bar, waka, wftm);
  const maker = await WakaMaker.deployed();
  await factory.setFeeTo(maker.address);

  await deployer.deploy(WakaSwapRouter02, factory.address, wftm);
};
