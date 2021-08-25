var WakaToken = artifacts.require('WakaToken');

module.exports = async function (deployer, network, accounts) {
    if (network === 'development' || network === 'fantomtest') {
        const EXCHANGE_ADDR = accounts[0];
        await deployer.deploy(WakaToken, EXCHANGE_ADDR, EXCHANGE_ADDR, EXCHANGE_ADDR, EXCHANGE_ADDR, EXCHANGE_ADDR);
    }
};
