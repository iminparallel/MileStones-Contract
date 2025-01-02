const { network } = require("hardhat");
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { verify } = require("../utils/verify");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  console.log(deployer);
  const mileStones = await deploy("MileStones", {
    from: deployer,
    args: [deployer],
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });
  log(`...........${mileStones.address}.............`);
  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(mileStones.address, [deployer]);
  }
};
module.exports.tags = ["all", "milestones"];
