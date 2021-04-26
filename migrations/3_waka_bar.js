var WakaBar = artifacts.require('WakaBar');
var WakaToken = artifacts.require('WakaToken');

module.exports = async function (deployer) {
  await deployer.deploy(WakaBar, (await WakaToken.deployed()).address);
};

/*
  const waka = "0x564E4EA3B8f14F3cAFa065ADF2bCF61af026b8F3";
  const weth9 = "0x9B3D447b335C4Ce2be80909c3B9b8C4744ff8D91";
  const factoryAddress = "0x98264dDE213F94DAfB72C81333E0Ac79eA563402";
  const factory = await MockWakaSwapFactory.at(factoryAddress);

  await deployer.deploy(WakaSwapRouter02, factoryAddress, weth9);

  await deployer.deploy(WakaBar, waka);
  const bar = (await WakaBar.deployed()).address;

  await deployer.deploy(WakaMaker, factoryAddress, bar, waka, weth9);
  factory.setFeeTo((await WakaMaker.deployed()).address);
*/