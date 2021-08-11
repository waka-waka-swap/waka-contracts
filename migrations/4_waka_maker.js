var WakaMaker = artifacts.require('WakaMaker');
var WakaSwapFactory = artifacts.require('WakaSwapFactory');
var WakaBar = artifacts.require('WakaBar');

module.exports = async function (deployer) {
  // await deployer.deploy(WakaSwapFactory, "FEE_TO_SETTER_ADDRESS");
  // const factory = await WakaSwapFactory.deployed();
  // const wftm = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  // const waka = "WAKA_TOKEN_ADDRESS";
  // const bar = (await WakaBar.deployed()).address;
  // await deployer.deploy(WakaMaker, factory.address, bar, waka, wftm);
  // factory.setFeeTo((await WakaMaker.deployed()).address);
};
