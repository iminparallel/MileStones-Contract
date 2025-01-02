// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MileStones {
    
    struct User {
        uint256 totalAmount;
        uint256 milestoneCompleted;
        uint256 amountWithdrawn;
    }

    mapping(address => User) public users;
    
    uint256 public milestoneCount = 4;
    uint256 public platformFeePercentage = 2; // Example platform fee of 2%
    address public platformWallet;

    event FundsLocked(address indexed user, uint256 amount);
    event MilestoneCompleted(address indexed user, uint256 milestone, uint256 amountReleased);
    event AllFundsWithdrawn(address indexed user, uint256 totalAmount);

    constructor(address _platformWallet) {
        require(_platformWallet != address(0), "Invalid platform wallet");
        platformWallet = _platformWallet;
    }

    function lockFunds() external payable {
        require(msg.value > 0, "Funds must be greater than 0");
        require(users[msg.sender].totalAmount == 0, "User already locked funds");

        uint256 fee = (msg.value * platformFeePercentage) / 100;
        uint256 netAmount = msg.value - fee;

        payable(platformWallet).transfer(fee);

        users[msg.sender] = User({
            totalAmount: netAmount,
            milestoneCompleted: 0,
            amountWithdrawn: 0
        });

        emit FundsLocked(msg.sender, netAmount);
    }

    function completeMilestone() external {
        User storage user = users[msg.sender];
        require(user.totalAmount > 0, "No funds locked");
        require(user.milestoneCompleted < milestoneCount, "All milestones already completed");

        uint256 milestoneAmount = user.totalAmount / milestoneCount;
        user.milestoneCompleted++;

        if (user.milestoneCompleted == milestoneCount) {
            // Final milestone: Release all remaining funds
            uint256 remainingAmount = user.totalAmount - user.amountWithdrawn;
            user.amountWithdrawn += remainingAmount;
            payable(msg.sender).transfer(remainingAmount);
            emit AllFundsWithdrawn(msg.sender, user.totalAmount);
        } else {
            user.amountWithdrawn += milestoneAmount;
            payable(msg.sender).transfer(milestoneAmount);
            emit MilestoneCompleted(msg.sender, user.milestoneCompleted, milestoneAmount);
        }
    }

    function getUserDetails(address _user) external view returns (User memory) {
        return users[_user];
    }
}
