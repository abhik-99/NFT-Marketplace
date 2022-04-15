const { task } = require("hardhat/config");

require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

task('deployToken', async(taskArgs, hre) => {
  const TokenContract = await hre.ethers.getContractFactory("TestToken");
  const token = await TokenContract.deploy();
  await token.deployed();

  console.log("Token contract Deployed to", token.address);
});

task('deployNft', async(taskArgs, hre) => {
  const NftContract = await hre.ethers.getContractFactory("TestNft");
  const nft = await NftContract.deploy();
  await nft.deployed();

  console.log("NFT contract Deployed to", nft.address);
});

task('deployMarketplace', "Deploys the marketplace contract")
.addParam("nftContract", "Address of the NFT Smart Contract")
.addParam("tokenContract", "Address of the ERC20 token Contract ")
.setAction(async(taskArgs, hre) => {
  const MarketplaceContract = await hre.ethers.getContractFactory("TestMarketplace");
  const marketplace = await MarketplaceContract.deploy(taskArgs.nftContract, taskArgs.tokenContract);
  await marketplace.deployed();

  console.log("Marketplace contract Deployed to", marketplace.address);
});


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.4",
  networks: {
    ropsten: {
      url: process.env.ROPSTEN_URL || "",
      accounts:
        process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
