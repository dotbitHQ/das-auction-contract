const { ethers, upgrades } = require('hardhat');
async function main() {
    const proxyAddress  = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512";//代理合约地址
    const Auction = await ethers.getContractFactory('auction');
    proxy = (await upgrades.upgradeProxy(proxyAddress, Auction));
    console.log(await upgrades.erc1967.getImplementationAddress(proxyAddress)," getImplementationAddress")//逻辑合约地址，地址可变，与proxy合约的状态变量需要EVM对齐
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});