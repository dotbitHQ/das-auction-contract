// scripts/upgrade_box.js
const { ethers, upgrades } = require('hardhat');

async function main () {
  const Auction = await ethers.getContractFactory('auction');
//todo:
//
//hardhat怎么找到admin proxy合约地址的

//bug:
//1.如果用代理的非owner来执行升级操作，由于升级操作是要创建两笔交易，一笔是创建新的逻辑合约，一笔是调用代理的admin合约的upgrade(address proxy, address implementation)
//方法，第一笔代理的非owner是可以创建成功的，但是第二笔需要owner权限，因此第二笔会失败
//2.切换成代理的owner，再次执行升级操作，它不会重新去部署逻辑合约，会使用上一次非owner创建的逻辑合约来调用代理的admin合约的upgrade方法。
//
//   await upgrades.upgradeProxy('0x0E6e6c8548866D0A359DbD00d51Df404721B5ce6', Auction);

//hardhat会检测新的逻辑合约是否有更改，如果没有的话，不会重新部署逻辑合约，只会调用代理合约的upgrade方法重新设置一次逻辑合约地址。
  console.log(await upgrades.erc1967.getImplementationAddress("0x0E6e6c8548866D0A359DbD00d51Df404721B5ce6")," getImplementationAddress");
  console.log(await upgrades.erc1967.getAdminAddress("0x0E6e6c8548866D0A359DbD00d51Df404721B5ce6")," getAdminAddress");//0x0818C6c38DB1dd7B5dfFc72F90e0D5489654987b
}

main();