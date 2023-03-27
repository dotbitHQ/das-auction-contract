
const { ethers, upgrades,config} = require('hardhat');
async function main() {
  UsdOracle = config.constructor_param.UsdOracle;
  StartPremium = config.constructor_param.StartPremium;
  TotalDays = config.constructor_param.TotalDays;

  if (UsdOracle == "" || UsdOracle == undefined) {
    console.log("constructor param UsdOracle error");
  }
  if (StartPremium == 0 || StartPremium == undefined) {
    console.log("constructor param StartPremium error");
  }
  if (TotalDays == 0 || TotalDays == undefined) {
    console.log("constructor param TotalDays error");
  }
  const Auction = await ethers.getContractFactory('auction');
  proxy = (await upgrades.deployProxy(Auction, [UsdOracle,StartPremium,TotalDays], {kind: 'uups'}, { initializer: 'initialize' }));
  console.log(await proxy.address, " proxy");//代理合约的地址 
  console.log(await upgrades.erc1967.getImplementationAddress(proxy.address)," getImplementationAddress")//逻辑合约地址
  //uups模式下没有代理管理合约：所以调用此方法的结果是0x0000000000000000000000000000000000000000
  console.log(await upgrades.erc1967.getAdminAddress(proxy.address)," getAdminAddress")//proxy admin，owner升级的时候会调用该合约的upgrade方法进行升级逻辑合约

}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
