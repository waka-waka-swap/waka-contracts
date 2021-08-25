var WakaIDO = artifacts.require('WakaIDO');

module.exports = async function (deployer, network) {
  if (network !== 'development' && network !== 'fantomtest') {
    return;
  }
  const raisingToken = "0xe065F7DAA5CC60CE0a96cF56d1B37dA59720b72b";
  const offeringToken = "0x3b2B31A443053829B5f849a84700DeE429E37F62";
  const registrationStartBlock = 1510294;
  const firstRoundStartBlock = 1510304;
  const firstRoundEndBlock = 1510305;
  const secondRoundEndBlock = 1510306;
  const holdTokensTillBlock = 1610306;
  const offeringAmount = "100000000000000000000";
  const raisingAmount = "50000000000000000000";
  const adminAddress = '0xEC0d3D2D58f71a6C34092B7fc4E8d6096c260037';
  const tiersContractAddress = '0x522404EF646e233137375E43E6F976cc5FBC852a';

  await deployer.deploy(
    WakaIDO,
    raisingToken,
    offeringToken,
    registrationStartBlock,
    firstRoundStartBlock,
    firstRoundEndBlock,
    secondRoundEndBlock,
    holdTokensTillBlock,
    offeringAmount,
    raisingAmount,
    adminAddress,
    tiersContractAddress
  );
};
