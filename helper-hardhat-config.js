const networkConfig = {
  11155111: {
    name: "sepolia",
    ethUsdPriceFeed: "0x694AA1769357215DE4FAC081bf1f309aDC325306",
  },
  656476: {
    name: "EDU",
    ethUsdPriceFeed: "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
  },
  421614: {
    name: "EDU",
    ethUsdPriceFeed: "0xd30e2101a97dcbAeBCBC04F14C3f624E67A35165",
  },
};
const developmentChains = ["hardhat", "localhost"];
const DECIMALS = 20;
const INITIAL_ANSWER = 35000000000000;
module.exports = {
  networkConfig,
  developmentChains,
  DECIMALS,
  INITIAL_ANSWER,
};
