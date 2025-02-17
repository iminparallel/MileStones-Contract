const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { assert, expect, chai } = require("chai");

developmentChains.includes(network.name)
  ? describe.skip
  : describe("MileStones", function () {
      let mileStones;
      let _platformWallet;
      let deployer;
      let accounts;
      const sendValue = ethers.parseEther("0.001");

      beforeEach(async () => {
        accounts = await ethers.getSigners();
        deployer = (await getNamedAccounts()).deployer;
        await deployments.fixture(["all"]);
        const mileStonesDeployment = await deployments.get("MileStones");
        mileStones = await ethers.getContractAt(
          "MileStones",
          mileStonesDeployment.address
        );
      });
      describe("complete milestones", function () {
        beforeEach(async () => {
          await mileStones.lockFunds({ value: sendValue });
        });
      });
    });
