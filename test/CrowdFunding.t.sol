// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.25;

import {Test, console} from "forge-std/Test.sol";
import { CrowdFunding } from "../src/CrowdFunding.sol";

contract CounterTest is Test {
    CrowdFunding public crowdfunding;

    address owner = address(1);
    address contributor = address(2);

    function setUp() public {
        crowdfunding = new CrowdFunding();
    }

    // Positive test cases
    function test_createCampaign() public {
        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit CrowdFunding.SuccessCampaignCreation(1);
        crowdfunding.createCampaign(10000, 1000);
        assertEq(crowdfunding.campaignCount(), 1);
        vm.stopPrank();
    }

    // Negative test cases
    function test_createCampaign_invalidGoal() public {
        vm.expectRevert(CrowdFunding.InvalidGoal.selector);
        crowdfunding.createCampaign(0, 1000);
    }

    // Positive test cases
    function test_contribute() public {
        vm.startPrank(owner);
        crowdfunding.createCampaign(1000, 1000);
        vm.stopPrank();
        vm.deal(contributor, 2000);
        vm.startPrank(contributor);
        vm.expectEmit(true, true, true, true);
        emit CrowdFunding.SuccessfullContribution(1, contributor, 1000);
        crowdfunding.contribute{value: 1000}(1);
        vm.stopPrank();
        assertEq(contributor.balance, 1000);
    }

    function test_createAndContributeCampaign() public {
        test_createCampaign();
        vm.deal(contributor, 1000);
        vm.startPrank(contributor);
        vm.expectEmit(true, true, true, true);
        emit CrowdFunding.SuccessfullContribution(1, contributor, 1000);
        crowdfunding.contribute{value: 1000}(1);
        vm.stopPrank();
        assertEq(contributor.balance, 0);
    }

    // // Negative test cases
    function test_contribute_campaignNotExist() public {
        vm.expectRevert(CrowdFunding.CampaignNotExist.selector);
        crowdfunding.contribute{value: 0}(1);
    }

     function test_contribute_invalidContribution() public {
        crowdfunding.createCampaign(1000, 1000);
        vm.expectRevert(CrowdFunding.InvalidContribution.selector);
        crowdfunding.contribute{value: 0}(1);
    }

    function test_contribute_deadlineReached() public {
        crowdfunding.createCampaign(1000, 1);
        vm.deal(msg.sender, 1000);
        vm.warp(2000000000);
        vm.expectRevert(
            abi.encodeWithSelector(CrowdFunding.DeadlineReached.selector, 2, 2000000000)
        );
        crowdfunding.contribute{value: 1000}(1);
    }

    // // Positive test cases
    function test_claimFundsRaised() public {
        test_createAndContributeCampaign();

        // Make sure campaign has reached deadline
        vm.warp(2000);

        vm.startPrank(owner);
        vm.expectEmit(true, true, true, true);
        emit CrowdFunding.SuccessFundClaimed(1, owner);
        crowdfunding.claimFundsRaised(1);
        vm.stopPrank();

        // Contributor contributes 1000 so owner should have 1000
        assertEq(owner.balance, 1000);
    }

    // // Negative test cases
    function test_claimFundsRaised_deadlineNotReached() public {
        test_createAndContributeCampaign();

        vm.startPrank(owner);
        vm.expectRevert(CrowdFunding.DeadlineNotReached.selector);
        crowdfunding.claimFundsRaised(1);
        vm.stopPrank();
    }

    function test_claimFundsRaisedNotOwner() public {
        test_createAndContributeCampaign();

        vm.expectRevert(CrowdFunding.NotCampaignOwner.selector);
        crowdfunding.claimFundsRaised(1);
    }

    function test_claimFundsRaisedCampaignNotExist() public {
        test_createAndContributeCampaign();

        vm.expectRevert(CrowdFunding.CampaignNotExist.selector);
        // Campaign is created twice so at id 3 there is no campaign yet
        crowdfunding.claimFundsRaised(3);
    }

    function test_claimFundsRaisedNoFundsToClaim() public {
        test_createCampaign();

        vm.warp(2000);
        vm.startPrank(owner);
        // TODO: Lets not pass 0 but get the actual value which will also be 0
        vm.expectRevert(
            abi.encodeWithSelector(CrowdFunding.NoFundsToClaim.selector, 0)
        );
        crowdfunding.claimFundsRaised(1);
        vm.stopPrank();
    }

    function test_claimFundsRaisedAlreadyClaimedFunds() public {
        test_claimFundsRaised();
        vm.startPrank(owner);
        vm.expectRevert(CrowdFunding.AlreadyClaimedFunds.selector);
        crowdfunding.claimFundsRaised(1);
        vm.stopPrank();
    }

    // // Positive test cases
    function test_withdrawContribution() public {
        test_createAndContributeCampaign();

        // Make sure campaign has reached deadline
        vm.warp(2000);

        vm.startPrank(contributor);
        vm.expectEmit(true, true, true, true);
        emit CrowdFunding.SuccessFundClaimed(1, contributor);
        crowdfunding.withdrawContribution(1);
        vm.stopPrank();

        assertEq(contributor.balance, 1000);
    }

    // Negative test cases
    function test_withdrawContribution_campaignNotExist() public {
        vm.expectRevert(CrowdFunding.CampaignNotExist.selector);
        crowdfunding.withdrawContribution(1);
    }

    function test_withdrawContribution_deadlineNotReached() public {
        test_createAndContributeCampaign();

        vm.expectRevert(CrowdFunding.DeadlineNotReached.selector);
        crowdfunding.withdrawContribution(1);
    }

    function test_withdrawContribution_noFundsToClaim() public {
        test_createCampaign();

        vm.warp(2000);
        vm.expectRevert(
            abi.encodeWithSelector(CrowdFunding.NoFundsToClaim.selector, 0)
        );
        crowdfunding.withdrawContribution(1);
    }

    function test_withdrawContribution_cannotWithdrawWhenGoalReached() public {
        test_createCampaign();
        vm.deal(contributor, 10000);
        vm.startPrank(contributor);
        crowdfunding.contribute{value: 10000}(1);

        vm.warp(2000);
        vm.expectRevert(
            abi.encodeWithSelector(CrowdFunding.CannotWithdrawWhenGoalReached.selector, 10000, 10000)
        );
        crowdfunding.withdrawContribution(1);
        vm.stopPrank();
    }
}
