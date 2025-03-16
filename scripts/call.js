// yarn hardhat run scripts/call.js --network edu
const hre = require("hardhat");

async function main() {
  const CONTRACT_ADDRESS = "0x419275ca1C99026A5e463a7880134c116B91c079"; // Replace with your deployed contract address
  const NEW_PRICE =
    hre.ethers.parseUnits("1000000000000") / BigInt(100000000000000); // Adjust the new price as needed
  //hre.ethers.parseUnits("10000000000000") / BigInt(100000000000000 -> this equals to 0.1
  // ethers.parseEther("0.0000001")
  const [deployer] = await hre.ethers.getSigners();

  console.log(`Using deployer address: ${deployer.address}`);

  const Milestones = await hre.ethers.getContractAt(
    "MileStones",
    CONTRACT_ADDRESS
  );

  console.log("Changing milestone price...");
  const tx = await Milestones.connect(deployer).changeMileStonePrice(NEW_PRICE);
  await tx.wait();

  console.log(`Milestone price changed successfully to: ${NEW_PRICE}`);
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
