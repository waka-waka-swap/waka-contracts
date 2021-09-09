var WakaTiers = artifacts.require('WakaTiers');
const { deployProxy } = require('@openzeppelin/truffle-upgrades');

module.exports = async function (deployer, network) {
  // if (network !== 'development' && network !== 'fantomtest') {
  //   return;
  // }
  const WAKA_ADDR = network === 'fantomtest'
    ? "0x1d02f74ca991e415916afab11c4d853784df8d9e"
    : "0xf61ccde1d4bb76ced1daa9d4c429cca83022b08b";
  const FEE_RECIPIENT = "0xEC0d3D2D58f71a6C34092B7fc4E8d6096c260037";
  const wakaTiers = await deployProxy(WakaTiers, undefined, { deployer });
  await wakaTiers.__WakaTiers_init(WAKA_ADDR, FEE_RECIPIENT, FEE_RECIPIENT);
};
