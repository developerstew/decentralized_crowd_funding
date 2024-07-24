// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import { CrowdFunding } from "../src/CrowdFunding.sol";

contract CrowdFundingScript is Script {
    CrowdFunding crowdFunding;

    function setUp() public {}

    function run() public {
        vm.broadcast();
        crowdFunding = new CrowdFunding{salt: keccak256("second_deployment")}();
    }
}
