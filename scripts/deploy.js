
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
  await proxy.deployed();
  console.log(await proxy.address, " proxy");//proxy contract address
  console.log(await upgrades.erc1967.getImplementationAddress(proxy.address)," getImplementationAddress")//logic contract address
}
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});



