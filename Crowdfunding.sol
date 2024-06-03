// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Crowdfunding {
    struct Campaign {
        address payable creator;
        uint256 goal;
        uint256 pledged;
        uint256 deadline;
        bool claimed;
    }

    uint256 public campaignCount;
    mapping(uint256 => Campaign) public campaigns;
    mapping(uint256 => mapping(address => uint256)) public pledges;

    event CampaignCreated(uint256 campaignId, address creator, uint256 goal, uint256 deadline);
    event Pledged(uint256 campaignId, address contributor, uint256 amount);
    event Claimed(uint256 campaignId, uint256 amount);
    event Refunded(uint256 campaignId, address contributor, uint256 amount);

    function createCampaign(uint256 goal, uint256 duration) external {
        campaignCount++;
        campaigns[campaignCount] = Campaign(
            payable(msg.sender),
            goal,
            0,
            block.timestamp + duration,
            false
        );
        emit CampaignCreated(campaignCount, msg.sender, goal, block.timestamp + duration);
    }

    function pledge(uint256 campaignId) external payable {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp < campaign.deadline, "Campaign has ended");
        campaign.pledged += msg.value;
        pledges[campaignId][msg.sender] += msg.value;
        emit Pledged(campaignId, msg.sender, msg.value);
    }

    function claim(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        require(msg.sender == campaign.creator, "Not campaign creator");
        require(block.timestamp > campaign.deadline, "Campaign is still active");
        require(campaign.pledged >= campaign.goal, "Goal not reached");
        require(!campaign.claimed, "Already claimed");

        campaign.claimed = true;
        campaign.creator.transfer(campaign.pledged);
        emit Claimed(campaignId, campaign.pledged);
    }

    function refund(uint256 campaignId) external {
        Campaign storage campaign = campaigns[campaignId];
        require(block.timestamp > campaign.deadline, "Campaign is still active");
        require(campaign.pledged < campaign.goal, "Goal reached, cannot refund");

        uint256 amount = pledges[campaignId][msg.sender];
        require(amount > 0, "No funds to refund");

        pledges[campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);
        emit Refunded(campaignId, msg.sender, amount);
    }
}
