var WakaIDO = artifacts.require('WakaIDO');

module.exports = async function (deployer, network) {
  // if (network !== 'development' && network !== 'fantomtest') {
  //   return;
  // }
  const raisingToken = "0x21be370d5312f44cb42ce377bc9b8a0cef1a4c83";
  const offeringToken = "0xf61ccde1d4bb76ced1daa9d4c429cca83022b08b";
  const registrationStartBlock = 16738939;
  const firstRoundStartBlock = 16957739;
  const firstRoundEndBlock = 17367739;
  const secondRoundEndBlock = 17567739;
  const holdTokensTillBlock = 17727739;
  const offeringAmount = "375000000000000000000000";
  const raisingAmount = "300000000000000000000000";
  const tiersContractAddress = '0x0bBb858b06f7E5F629778d4Ed99C31e20667858C';

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
    tiersContractAddress
  );
};
