// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";
import {Asset} from "../../src/asset/Asset.sol";

contract AssetTest is Test, GenericTest {

    Asset public asset;

    function setUp() public {
        asset = new Asset();
        vm.deal(acc1, 25);
        vm.prank(acc1);
        asset.topUp{ value : 25 }();
    }

    function testPriceIsCorrect() public {
        assertTrue(
            address(asset).balance == 25,
            "Money not sent to account"
        );
        assertTrue(
            asset.pricePerShare() == 25,
            "Price not set correctly"
        );
    }

    function testBuy() public {
        vm.deal(acc1, 50);
        vm.prank(acc1);
        asset.buy{ value : 50 }(2);
        assertTrue(
            asset.balanceOf(acc1) == 2,
            "Didn't add the shares"
        );
    }

    function testPriceIncreaseViaTopUp() public {
        // Build the new total value up to 100
        vm.deal(acc1, 75);
        vm.prank(acc1);
        asset.topUp{ value : 75 }();
        assertTrue(
            asset.pricePerShare() == 100,
            "Didn't increase price"
        );
    }

    function testPriceDecreaseViaWithdraw() public {
        vm.startPrank(acc1);
        asset.withdraw(20);
        vm.stopPrank();
        assertTrue(
            asset.pricePerShare() == 5,
            "Didn't decrease price"
        );
        assertTrue(
            acc1.balance == 20,
            "Didn't send money"
        );
    }
}
