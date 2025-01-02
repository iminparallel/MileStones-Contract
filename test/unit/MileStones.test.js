const { network, deployments, ethers } = require("hardhat");
const { developmentChains } = require("../../helper-hardhat-config");
const { assert, expect, chai } = require("chai");

!developmentChains.includes(network.name)
  ? describe.skip
  : describe("MileStones", function () {
      let mileStones;
      let _platformWallet;
      let deployer;
      let accounts;
      const sendValue = ethers.parseEther("1");

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

      describe("constructor", async function () {
        it("sets the _platformWallet correctly", async () => {
          const _platformWallet = await mileStones._platformWallet;
          assert.equal(_platformWallet, deployer.target);
        });
      });

      describe("lock funds", async function () {
        it("fails if the user does not send money", async () => {
          await expect(mileStones.lockFunds()).to.be.reverted;
        });

        it("locks funds", async () => {
          await mileStones.lockFunds({ value: sendValue });
          const response = await mileStones.getUserDetails(deployer);
          amount = Number(sendValue) * 0.98;
          assert.equal(Math.abs(Number(response[0])), Math.abs(amount));
        });
      });

      describe("complete milestones", function () {
        beforeEach(async () => {
          await mileStones.lockFunds({ value: sendValue });
        });

        it("complete milestone for a single funder", async function () {
          //await mileStones.lockFunds({ value: sendValue });
          const remainingAmount = await mileStones.getUserDetails(deployer);
          const startingUserBalance = await ethers.provider.getBalance(
            deployer
          );
          await mileStones.completeMilestone();
          const remainingAmountAfterMilestone = await mileStones.getUserDetails(
            deployer
          );
          const endingUserBalance = await ethers.provider.getBalance(deployer);

          remainingAmountChange =
            Number(remainingAmount[0]) -
            Number(remainingAmountAfterMilestone[0]);
          userBalanceChange =
            Number(endingUserBalance) - Number(startingUserBalance);
          assert.equal(
            Math.abs(Number(remainingAmountAfterMilestone[2])),
            Math.abs(Number(sendValue) * 0.98 * 0.25)
          );
        });

        it("expect 5th milestone to fail", async function () {
          for (let i = 0; i < 4; i++) {
            await mileStones.completeMilestone();
          }
          await expect(mileStones.completeMilestone()).to.be.reverted;
        });

        it("calculate amount withdrawn after completion", async function () {
          for (let i = 0; i < 4; i++) {
            await mileStones.completeMilestone();
          }
          const remainingAmountAfterMilestone = await mileStones.getUserDetails(
            deployer
          );
          assert.equal(
            Math.abs(Math.abs(Number(remainingAmountAfterMilestone[2]))),
            Math.abs(Number(sendValue) * 0.98)
          );
        });
      });

      describe("complete milestones for multiple users", function () {
        it("works for multiple participants", async function () {
          const accounts = await ethers.getSigners();
          let remainingAmountAfterMilestone;
          for (let i = 3; i < 6; i++) {
            const mileStonesContract = await mileStones.connect(accounts[i]);
            await mileStonesContract.lockFunds({ value: sendValue });
            remainingAmountBeforeMilestone =
              await mileStonesContract.getUserDetails(accounts[i]);
            for (let i = 0; i < 4; i++) {
              await mileStonesContract.completeMilestone();
            }
            const remainingAmountAfterMilestone =
              await mileStonesContract.getUserDetails(accounts[i]);
            console.log(remainingAmountAfterMilestone);
            assert.equal(
              Math.abs(Math.abs(Number(remainingAmountAfterMilestone[0]))),
              Math.abs(Number(sendValue) * 0.98)
            );
          }
        });
      });
    });
