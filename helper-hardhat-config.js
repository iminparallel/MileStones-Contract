const networkConfig = {
  11155111: {
    name: "sepolia",
    ethUsdPriceFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
  },
  656476: {
    name: "EDU",
  },
};
const developmentChains = ["hardhat", "localhost"];
const DECIMALS = 1;
const INITIAL_ANSWER = 10;
module.exports = {
  networkConfig,
  developmentChains,
  DECIMALS,
  INITIAL_ANSWER,
};
