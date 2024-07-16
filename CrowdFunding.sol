// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;
import "forge-std/console.sol";

contract CrowdFunding {
    struct Campaign {
        address owner;
        uint256 fundingGoal;
        uint256 deadline;
        uint256 fundsRaised;
        bool claimed;
        mapping(address => uint256) contributions;
        address[] contributors;
    }

    // mapping(uint256 => Campaign) private campaigns;
      mapping(uint256 => Campaign) public campaigns;
      uint256 public campaignCount = 0;

    // Events
    event SuccessfullContribution(uint256 indexed campaignId, address contributor, uint256 amount);
    event SuccessFundClaimed(uint256 indexed campaignId,address contributor);
    event SuccessCampaignCreation(uint256 indexed campaignId);

    // Errors
    error InvalidGoal();
    error InvalidContribution();
    error DeadlineReached(uint256 _deadline, uint256 _currentTime);
    error NotCampaignOwner();
    error FundClaimFail();
    error AlreadyClaimedFunds();
    error DeadlineNotReached();
    error NoFundsToClaim(uint256 _contribution);
    error CampaignNotExist();
    error CannotWithdrawWhenGoalReached(uint256 _fundsRaised, uint256 _fundsNeeded);

    // Modifiers
    modifier isCampaignOwner(uint256 _campaignId) {
        // We have to make sure the campaign exists before checking the owner, cant have owner without existing campaign
        if(campaigns[_campaignId].owner != address(0) && campaigns[_campaignId].owner != msg.sender) {
            revert NotCampaignOwner();
        }
        _;
    }

     modifier doesCampaignExist(uint _campaignId) {
        if(campaigns[_campaignId].owner == address(0)) {
            revert CampaignNotExist();
        }
        _;
    }

    function createCampaign(uint256 _fundingGoal, uint256 _duration) external {
        if (_fundingGoal == 0) revert InvalidGoal();
        campaignCount ++;
        Campaign storage newCampaign = campaigns[campaignCount];
        newCampaign.deadline = block.timestamp + _duration;
        newCampaign.owner = msg.sender;
        newCampaign.fundingGoal = _fundingGoal;
        emit SuccessCampaignCreation(campaignCount);
    }

    function contribute(uint256 _campaignId) doesCampaignExist(_campaignId) external payable  {
        if(msg.value == 0) {
            revert InvalidContribution();
        }

         Campaign storage existingCampaign = campaigns[_campaignId];

        if(existingCampaign.deadline < block.timestamp) revert DeadlineReached(existingCampaign.deadline, block.timestamp);

        if(existingCampaign.contributions[msg.sender] == 0){
            existingCampaign.contributors.push(msg.sender);
        }

        existingCampaign.fundsRaised += msg.value;
        existingCampaign.contributions[msg.sender] = msg.value;
        emit SuccessfullContribution(_campaignId, msg.sender, msg.value);
    }

    function claimFundsRaised(uint256 _campaignId) doesCampaignExist(_campaignId) isCampaignOwner(_campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];

        if(campaign.deadline > block.timestamp) revert DeadlineNotReached();

        if(campaign.fundsRaised == 0) revert NoFundsToClaim(campaign.fundsRaised);

        if(campaign.claimed == true) revert AlreadyClaimedFunds();
        
         campaign.claimed = true;

        (bool sent, ) = msg.sender.call{value: campaign.fundsRaised}("");
        if(!sent) revert FundClaimFail();

        emit SuccessFundClaimed(_campaignId, msg.sender);
    }

    // Run test here by starting the campaign and faking with deadline reached timestamp
    function withdrawContribution(uint256 _campaignId) doesCampaignExist(_campaignId) external {
        Campaign storage campaign = campaigns[_campaignId];

        if(campaign.deadline > block.timestamp) revert DeadlineNotReached();
         
        if(campaign.contributions[msg.sender] == 0) revert NoFundsToClaim(campaign.contributions[msg.sender]);
         
        if(campaign.fundsRaised >= campaign.fundingGoal) revert CannotWithdrawWhenGoalReached(campaign.fundsRaised, campaign.fundingGoal);
         
        (bool sent, ) = msg.sender.call{value: campaign.contributions[msg.sender]}("");
        if(!sent) revert FundClaimFail();
        emit SuccessFundClaimed(_campaignId,msg.sender);
    }
}
