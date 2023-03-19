require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
const ALCHEMY_API_KEY = "";

const GOERLI_PRIVATE_KEY = "";

module.exports = {
  solidity: "0.8.9", // solidity的编译版本
  // networks: {
  //   goerli: {
  //     url: `https://goerli.infura.io/v3/${ALCHEMY_API_KEY}`,
  //     accounts: [GOERLI_PRIVATE_KEY]
  //   }
  // }
};