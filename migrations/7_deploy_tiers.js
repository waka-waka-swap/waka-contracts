var WakaTiers = artifacts.require('WakaTiers');

module.exports = async function (deployer) {
  const WAKA_ADDR = "0x1d02f74ca991e415916afab11c4d853784df8d9e";
  const FEE_RECIPIENT = "0xEC0d3D2D58f71a6C34092B7fc4E8d6096c260037";
  await deployer.deploy(WakaTiers, WAKA_ADDR, FEE_RECIPIENT);
};
