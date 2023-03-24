// const hre = require("hardhat");
const { ethers, upgrades } = require('hardhat');
async function main() {
  const Auction = await ethers.getContractFactory("auction");
  //deployProxy方法会部署三个合约：代理合约，代理的admin合约，逻辑合约
  const auctionProxy = await upgrades.deployProxy(Auction, ["0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",100000000,21], { initializer: 'init' });
  await auctionProxy.deployed();

  console.log( auctionProxy.address," auction(proxy) address");//proxy地址:永远不变的地址，状态变量合约，用户与之交互的合约
  console.log(await upgrades.erc1967.getImplementationAddress(auctionProxy.address)," getImplementationAddress")//逻辑合约地址，地址可变，与proxy合约的状态变量需要EVM对齐
  console.log(await upgrades.erc1967.getAdminAddress(auctionProxy.address)," getAdminAddress")//proxy admin，owner升级的时候会调用该合约的upgrade方法进行升级逻辑合约
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
