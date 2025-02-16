// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MileStones {
    
    struct Milestone {
        address creator;
        uint256 totalAmount;
        uint256 milestoneCompleted;
        uint256 amountWithdrawn;
        uint256 createdAt;
        bool isCompleted;
        uint256 endsAt;
    }

    mapping(address => mapping( string => Milestone)) private milestones;
    
    uint256 private constant MILESTONE_COUNT = 5;
    uint256 private constant PLATFORM_PERCENTAGE = 5; // Example platform fee of 2%
    uint256 private owner_balance ;
    address private platformWallet;
    string[] private activeMilestones;

    event FundsLocked(address indexed user, uint256 amount);
    event MilestoneCompleted(address indexed user, uint256 milestone, uint256 amountReleased);
    event AllFundsWithdrawn(address indexed user, uint256 totalAmount);
    event OwnersWithdrawl(address creator, uint256 amount);

    constructor(address _platformWallet) {
        require(_platformWallet != address(0), "Invalid platform wallet");
        platformWallet = _platformWallet;
        owner_balance = 0;
    }

    modifier onlyOwner() {
        require(platformWallet == msg.sender, "Only the creator can perform this action");
        _;
    }

    modifier onlyCreator(string memory productId) {
        require(milestones[msg.sender][productId].creator == msg.sender, "Only the creator can perform this action");
        _;
    }

    function lockFunds(string memory productId) external payable {
        require(msg.value > 0, "Funds must be greater than 0");
        require(milestones[msg.sender][productId].totalAmount == 0, "User already locked funds");
        activeMilestones.push(productId);
        uint256 fee = (msg.value * PLATFORM_PERCENTAGE) / 100;
        uint256 netAmount = msg.value - fee;
        owner_balance += fee;
        uint256 endsAt = block.timestamp + 3600*24*7;

        //payable(platformWallet).transfer(fee);

        milestones[msg.sender][productId] = Milestone({
            creator: msg.sender,
            totalAmount: netAmount,
            milestoneCompleted: 0,
            amountWithdrawn: 0,
            createdAt: block.timestamp,
            isCompleted: false,
            endsAt: endsAt
        });

        emit FundsLocked(msg.sender, netAmount);
    }

    function completeMilestone(string memory productId) external onlyCreator(productId){
        Milestone storage milestone = milestones[msg.sender][productId];
        require(milestone.totalAmount > 0, "No funds locked");
        require(milestone.milestoneCompleted < MILESTONE_COUNT, "All milestones already completed");

        uint256 milestoneAmount = milestone.totalAmount / MILESTONE_COUNT;
        milestone.milestoneCompleted++;

        if (milestone.milestoneCompleted == MILESTONE_COUNT) {
            // Final milestone: Release all remaining funds
            string[] memory copiedActiveMilestone = activeMilestones;
            string[] memory updateMileStones = new string[] (copiedActiveMilestone.length - 1);
            uint256 j;
            j = 0;
            for (uint256 i = 0; i < copiedActiveMilestone.length; i++){
                if (keccak256(abi.encodePacked(copiedActiveMilestone[i])) != keccak256(abi.encodePacked(productId))) {
                    updateMileStones[j] = copiedActiveMilestone[i];
                    j+=1;
                }
            }
            activeMilestones = updateMileStones;

            uint256 remainingAmount = milestone.totalAmount - milestone.amountWithdrawn;
            milestone.amountWithdrawn += remainingAmount;
            milestone.isCompleted = true;
            payable(msg.sender).transfer(remainingAmount);
            emit AllFundsWithdrawn(msg.sender, milestone.totalAmount);
        } else {
            milestone.amountWithdrawn += milestoneAmount;
            payable(msg.sender).transfer(milestoneAmount);
            emit MilestoneCompleted(msg.sender, milestone.milestoneCompleted, milestoneAmount);
        }
    }

    function ownersWithdrawl( uint256 amount) external onlyOwner() {
        require(amount <= owner_balance, "Amount exceeds collected funds");
        payable(msg.sender).transfer(amount);
        owner_balance -= amount;
        emit OwnersWithdrawl(msg.sender, amount);
    }

    function getUserMilestoneDetails(address _user, string memory productId) external view returns (Milestone memory) {
        return milestones[_user][productId];
    }
}
