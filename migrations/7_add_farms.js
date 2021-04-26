var WakaSwapLibrary = artifacts.require('WakaSwapLibrary');
var WakaToken = artifacts.require('WakaToken');
var MockERC20 = artifacts.require('MockERC20');
var WakaSwapRouter02 = artifacts.require('WakaSwapRouter02');

const { pack, keccak256 } = require('@ethersproject/solidity')
const { getCreate2Address } = require('@ethersproject/address')

module.exports = async function (deployer) {
    const recipient = "0xe23364Ab077B07Cf4eF6bff4e99FE99BC3C8CeB4"
    const fTest = await MockERC20.at("0x9BBd116Da36915Fb3E454231de1434256bc381B8")
    const fUSD = await MockERC20.at("0x42281EA641b1eBf21C01f275057DA046d481e646")
    const waka = await WakaToken.at("0x25eB65f85A7f1ca4E9C5169D6E4b04C0ecF000F4")
    const router = await WakaSwapRouter02.at("0x6E983BaF374d668f064f8230b661E6e17b81578c")
    await router.addLiquidity(fTest.address, waka.address, "100000000000000000000", "100000000000000000000", 0, 0, recipient, Math.floor(new Date().getTime() / 1000 + 10000000))
    await router.addLiquidity(fUSD.address, waka.address, "100000000000000000000", "100000000000000000000", 0, 0, recipient, Math.floor(new Date().getTime() / 1000 + 10000000))
    await router.addLiquidity(fTest.address, fUSD.address, "100000000000000000000", "100000000000000000000", 0, 0, recipient, Math.floor(new Date().getTime() / 1000 + 10000000))
    const lpToken1 = getCreate2Address(
        "0xb920F76f2B4bfAA033084743f3fF32C5122AA673",
        keccak256(['bytes'], [pack(['address', 'address'], ["0x25eB65f85A7f1ca4E9C5169D6E4b04C0ecF000F4", "0x9BBd116Da36915Fb3E454231de1434256bc381B8"])]),
        "0xb024d5b7a1067029cd52e3a53b003f3aad171f26f73a8c207d331e116b490be4"
    )
    console.log(lpToken1)
    const lpToken2 = getCreate2Address(
        "0xb920F76f2B4bfAA033084743f3fF32C5122AA673",
        keccak256(['bytes'], [pack(['address', 'address'], ["0x25eB65f85A7f1ca4E9C5169D6E4b04C0ecF000F4", "0x42281EA641b1eBf21C01f275057DA046d481e646"])]),
        "0xb024d5b7a1067029cd52e3a53b003f3aad171f26f73a8c207d331e116b490be4"
    )
    console.log(lpToken2)
    const lpToken3 = getCreate2Address(
        "0xb920F76f2B4bfAA033084743f3fF32C5122AA673",
        keccak256(['bytes'], [pack(['address', 'address'], ["0x42281EA641b1eBf21C01f275057DA046d481e646", "0x9BBd116Da36915Fb3E454231de1434256bc381B8"])]),
        "0xb024d5b7a1067029cd52e3a53b003f3aad171f26f73a8c207d331e116b490be4"
    )
    console.log(lpToken3)
    const waka = await WakaToken.at("0x25eB65f85A7f1ca4E9C5169D6E4b04C0ecF000F4")
    await waka.mintTo("0xe23364Ab077B07Cf4eF6bff4e99FE99BC3C8CeB4", "10000000000000000000000")
};
