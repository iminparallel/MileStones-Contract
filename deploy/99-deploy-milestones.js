const fs = require("fs");
const { network, deployments, ethers } = require("hardhat");
const FRONT_END_ADDRESSES =
  "/Users/haritchowdhury/loader/src/constants/ContractAddresses.json";
const FRONT_END_ABI = "/Users/haritchowdhury/loader/src/constants/abi.json";

module.exports = async () => {
  console.log("updating front end");
  updateContractAddresses();
  updateAbi();
};

async function updateContractAddresses() {
  let mileStones;
  const mileStonesDeployment = await deployments.get("MileStones");
  mileStones = await ethers.getContractAt(
    "MileStones",
    mileStonesDeployment.address
  );
  const chainId = network.config.chainId.toString();
  const addresses = fs.readFileSync(FRONT_END_ADDRESSES, "utf8");

  const currentAddresses = JSON.parse(addresses);
  if (chainId in currentAddresses) {
    if (!currentAddresses[chainId].includes(mileStones.target)) {
      currentAddresses[chainId].push(mileStones.target);
    }
  } else {
    currentAddresses[chainId] = [mileStones.target];
  }
  fs.writeFileSync(FRONT_END_ADDRESSES, JSON.stringify(currentAddresses));
  console.log("done");
}
async function updateAbi() {
  let mileStones;
  const mileStonesDeployment = await deployments.get("MileStones");
  mileStones = await ethers.getContractAt(
    "MileStones",
    mileStonesDeployment.address
  );
  console.log(JSON.stringify(mileStones.interface.format("json")));

  fs.writeFileSync(
    FRONT_END_ABI,
    JSON.stringify(mileStones.interface.format("json"))
  );
}
module.exports.tags = ["all", "frontend"];
