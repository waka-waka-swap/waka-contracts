var WakaBar = artifacts.require('WakaBar');
var WakaMaker = artifacts.require('WakaMaker');
var WakaSwapFactory = artifacts.require('WakaSwapFactory');
var WakaSwapRouter02 = artifacts.require('WakaSwapRouter02');

module.exports = async function (deployer, network) {
  if (network !== 'development' && network !== 'fantomtest') {
    return;
  }
  const waka = "0xf61ccde1d4bb76ced1daa9d4c429cca83022b08b";
  const feeToSetter = "0xE4419E58D9303327D78B2591232C9cde03806694";
  const wftm = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";

  await deployer.deploy(WakaBar, waka);
  await deployer.deploy(WakaSwapFactory, feeToSetter);

  const bar = (await WakaBar.deployed()).address;
  const factory = await WakaSwapFactory.deployed();

  await deployer.deploy(WakaMaker, factory.address, bar, waka, wftm);
  const maker = await WakaMaker.deployed();
  await factory.setFeeTo(maker.address);

  await deployer.deploy(WakaSwapRouter02, "0x47b8735D2D51624fF7AcfC6F66aC6647ffc92afB", "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83");
};
