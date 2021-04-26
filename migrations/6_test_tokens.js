var WakaToken = artifacts.require('WakaToken');
var WakaFarm = artifacts.require('WakaFarm');
var MockERC20 = artifacts.require('MockERC20');

module.exports = async function (deployer) {
    // await deployer.deploy(MockERC20, "FantomTest", "FTT", "100000000000000000000000");
    // await deployer.deploy(MockERC20, "FantomUSD", "fUSD", "100000000000000000000000");
    const recipient = "0x2A26602CdFd04EF7B3dFae772A909487f8866E77"
    const fTest = await MockERC20.at("0x9BBd116Da36915Fb3E454231de1434256bc381B8")
    const fUSD = await MockERC20.at("0x42281EA641b1eBf21C01f275057DA046d481e646")
    await fTest.transfer(recipient, "5000000000000000000000")
    await fUSD.transfer(recipient, "5000000000000000000000")

    const waka = await WakaToken.at("0x25eB65f85A7f1ca4E9C5169D6E4b04C0ecF000F4")
    await waka.mintTo(recipient, "10000000000000000000000")
    // const farm = await WakaFarm.at("0x97f789c25DF0763D93F782d91D13908cEe236aFc")
    // await waka.approve("0x97f789c25DF0763D93F782d91D13908cEe236aFc", "1000000000000000000000000000")
    // await farm.add(100, waka.address, false)
    const myAddr = "0xD7D4587b5524b32e24F1eE7581D543C775df27B5";
    console.log("FantomTest balance ------>", (await fTest.balanceOf(myAddr)).toString())
    console.log("FantomUSD balance ------>", (await fUSD.balanceOf(myAddr)).toString())
};
