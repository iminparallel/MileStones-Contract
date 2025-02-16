// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
error Milestones__UpkeepNotNeeded(uint256 currentBalance, uint256 numPlayers, uint256 raffleState);


contract MileStones is AutomationCompatibleInterface {
    
    enum MileStoneState {
        OPEN,
        CALCULATING
    }

    struct Milestone {
        address creator;
        uint256 totalMilestones;
        uint256 totalAmount;
        uint256 milestoneCompleted;
        uint256 amountWithdrawn;
        uint256 createdAt;
        bool isCompleted;
        uint256 endsAt;
    }

    mapping(string => Milestone) private products; // Do they get mapped to the same Milestone
    
    uint256 private constant MILESTONE_COUNT = 5;
    uint256 private constant PLATFORM_PERCENTAGE = 5; // Platform fee of 5%
    uint256 private owner_balance ;
    address private platformWallet;
    string[] private activeMilestones;

    uint256 private immutable i_interval;
    uint256 private s_lastTimeStamp;

    event FundsLocked(address indexed user, uint256 amount);
    event MilestoneCompleted(address indexed user, uint256 milestone, uint256 amountReleased);
    event AllFundsWithdrawn(address indexed user, uint256 totalAmount);
    event OwnersWithdrawl(address indexed creator, uint256 amount);
    
    MileStoneState private s_milestoneState;

    constructor(address _platformWallet, uint256 interval) {
        require(_platformWallet != address(0), "Invalid platform wallet");
        platformWallet = _platformWallet;
        owner_balance = 0;
        s_lastTimeStamp = block.timestamp;
        i_interval = interval;
    }

    modifier onlyOwner() {
        require(platformWallet == msg.sender, "Only the creator can perform this action");
        _;
    }

    modifier onlyCreator(string memory productId) {
        require(products[productId].creator == msg.sender, "Only the platform wallet can perform this action");
        _;
    }

    function lockFunds(string memory productId) external payable {
        require(msg.value > 0, "Funds must be greater than 0");
        require(products[productId].totalAmount == 0, "User already locked funds");
        activeMilestones.push(productId);
        uint256 fee = (msg.value * PLATFORM_PERCENTAGE) / 100;
        uint256 netAmount = msg.value - fee;
        owner_balance += fee;
        uint256 endsAt = block.timestamp + 3600*24*7;

        //payable(platformWallet).transfer(fee);
        
        products[productId] = Milestone({
            creator: msg.sender,
            totalMilestones: MILESTONE_COUNT, 
            totalAmount: netAmount,
            milestoneCompleted: 0,
            amountWithdrawn: 0,
            createdAt: block.timestamp,
            isCompleted: false,
            endsAt: endsAt
        });


        emit FundsLocked(msg.sender, netAmount);
    }

    function checkUpkeep(bytes memory /* checkData */ )
        public
        view
        override
        returns (bool upkeepNeeded, bytes memory /* performData */ )
    {
        bool isOpen = MileStoneState.OPEN == s_milestoneState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        bool hasActiveMilestones = activeMilestones.length > 0;
        bool hasBalance = address(this).balance > 0;
        upkeepNeeded = (timePassed && isOpen && hasBalance && hasActiveMilestones);
        return (upkeepNeeded, "0x0"); // can we comment this out?
    }


    function performUpkeep(bytes calldata /* performData */ ) external override {
        (bool upkeepNeeded,) = checkUpkeep("");
        // require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Milestones__UpkeepNotNeeded(address(this).balance, activeMilestones.length, uint256(s_milestoneState));
        }
        s_milestoneState = MileStoneState.CALCULATING;
        string[] memory copiedActiveMilestone = activeMilestones;
        uint256 temp_owner_balance = owner_balance;
        uint256 j;
        j = 0;
        for (uint256 i = 0; i < copiedActiveMilestone.length; i++){
            string memory milestoneId = copiedActiveMilestone[i];
            Milestone storage milestone =  products[milestoneId];
            if (milestone.endsAt > block.timestamp) {
                j+=1;
            }
        }
        string[] memory updatedMileStones = new string[](j);
        j = 0;
        for (uint256 i = 0; i < copiedActiveMilestone.length; i++){
            string memory milestoneId = copiedActiveMilestone[i];
            Milestone storage milestone =  products[milestoneId];
            if (milestone.endsAt > block.timestamp) {
                updatedMileStones[j] = copiedActiveMilestone[i];
                j+=1;
            }else{
                temp_owner_balance += milestone.totalAmount -  milestone.amountWithdrawn;
                milestone.isCompleted = true;
                milestone.amountWithdrawn = milestone.totalAmount;
            }
            products[milestoneId] = milestone;
        }
        owner_balance = temp_owner_balance;
        activeMilestones = updatedMileStones;
        s_lastTimeStamp = block.timestamp;
        s_milestoneState = MileStoneState.OPEN;
    }

    function completeMilestone(string memory productId) external onlyCreator(productId){
        Milestone storage product = products[productId];
        require(product.totalAmount > 0, "No funds locked");
        require(product.endsAt <= block.timestamp, "Milestone Expired");
        require(product.milestoneCompleted < product.totalMilestones, "All milestones already completed");

        uint256 milestoneAmount = product.totalAmount / product.totalMilestones;
        product.milestoneCompleted++;

        if (product.milestoneCompleted == product.totalMilestones) {
            // Final milestone: Release all remaining funds
            string[] memory copiedActiveMilestone = activeMilestones;
            string[] memory updatedMileStones = new string[] (copiedActiveMilestone.length - 1);
            uint256 j;
            j = 0;
            for (uint256 i = 0; i < copiedActiveMilestone.length; i++){
                if (keccak256(abi.encodePacked(copiedActiveMilestone[i])) != keccak256(abi.encodePacked(productId))) {
                    updatedMileStones[j] = copiedActiveMilestone[i];
                    j+=1;
                }
            }
            activeMilestones = updatedMileStones;

            uint256 remainingAmount = product.totalAmount - product.amountWithdrawn;
            product.amountWithdrawn += remainingAmount;
            product.isCompleted = true;
            payable(msg.sender).transfer(remainingAmount);
            emit AllFundsWithdrawn(msg.sender, product.totalAmount);
        } else {
            product.amountWithdrawn += milestoneAmount;
            payable(msg.sender).transfer(milestoneAmount);
            emit MilestoneCompleted(msg.sender, product.milestoneCompleted, milestoneAmount);
        }
    }

    function ownersWithdrawl( uint256 amount) external onlyOwner() {
        require(amount <= owner_balance * 70 / 100, "Amount exceeds collected funds");
        payable(msg.sender).transfer(amount);
        owner_balance -= amount;
        emit OwnersWithdrawl(msg.sender, amount);
    }

    function getUserMilestoneDetails(string memory productId) external onlyOwner() onlyCreator(productId) view returns (Milestone memory) {
        return products[productId];
    }
}
