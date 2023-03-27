require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
/** @type import('hardhat/config').HardhatUserConfig */
const ALCHEMY_API_KEY = "";

const GOERLI_PRIVATE_KEY = "";

module.exports = {
  solidity: "0.8.9", // solidity的编译版本
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${ALCHEMY_API_KEY}`,
      accounts: [GOERLI_PRIVATE_KEY]
    }
  },
  constructor_param : {
    UsdOracle : "0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e",
    StartPremium : 100000000,
    TotalDays : 21,
  },
};