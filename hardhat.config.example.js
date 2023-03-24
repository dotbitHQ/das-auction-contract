require("@nomicfoundation/hardhat-toolbox");
// require("@nomiclabs/hardhat-waffle");
require('@nomiclabs/hardhat-ethers');
require('@openzeppelin/hardhat-upgrades');
/** @type import('hardhat/config').HardhatUserConfig */
const API_KEY = "";

const PRIVATE_KEY = "";

module.exports = {
  solidity: "0.8.9", // solidity的编译版本
  networks: {
    goerli: {
      url: `https://goerli.infura.io/v3/${API_KEY}`,
      accounts: [PRIVATE_KEY]
    }
  }
};