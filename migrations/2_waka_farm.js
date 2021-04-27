var WakaFarm = artifacts.require('WakaFarm');
var WakaToken = artifacts.require('WakaToken');

module.exports = async function (deployer) {
    const myAddr = "0xD7D4587b5524b32e24F1eE7581D543C775df27B5";
    const waka = await WakaToken.at("0x4AAD5329998dc9aCacd82B065573731986bCe174")
    await deployer.deploy(
        WakaFarm,
        waka.address,
        myAddr,
        "25000000000000000000",
        "1618695400",
        "1618699000",
        "120",
        "625000000000000000",
        "625000000000000000"
    )
    const farm = await WakaFarm.deployed()
    await waka.approve(farm.address, "1000000000000000000000000000")
    await farm.add(100, waka.address, false)
};
/*
Ropsten
"9771234",
"9777734",
"6500",

Fantom
"386085",
"836085",
"15000",
*/