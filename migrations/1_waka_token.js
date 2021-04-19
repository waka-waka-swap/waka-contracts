var WakaToken = artifacts.require('WakaToken');

module.exports = async function (deployer) {
    const EXCHANGE_ADDR = "0x";
    const TREASURY_ADDR = "0x";
    await deployer.deploy(WakaToken, EXCHANGE_ADDR, TREASURY_ADDR);
};
