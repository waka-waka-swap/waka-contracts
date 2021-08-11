var WakaIDO = artifacts.require('WakaIDO');

module.exports = async function (deployer) {
  const raisingToken = "0xd824BB4da0BBD047091dFd5604C906891Ff8f98f";
  const offeringToken = "0x298E5Ef87309d36Db693290353e897291df961CA";
  const registrationStartBlock = 313;
  const firstRoundStartBlock = 319;
  const firstRoundEndBlock = 329;
  const secondRoundEndBlock = 335;
  const holdTokensTillBlock = 345;
  const offeringAmount = 100000;
  const raisingAmount = 50000;
  const adminAddress = '0xaAAda437884e3241d8638CA667bB68466d31ad9d';
  const tiersContractAddress = '0xC4e8F2346df141DcCeb14475Ca3c7E369d67168A';

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
