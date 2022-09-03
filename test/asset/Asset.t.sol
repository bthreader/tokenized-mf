// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";
import {Asset} from "../../src/asset/Asset.sol";

contract AssetTest is Test, GenericTest {

    Asset public asset;

    function setUp() public {
        // Price = 25
        // Shares = 1
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

    function testBuyAsset() public {
        vm.deal(acc2, 50);
        vm.prank(acc2);
        asset.buy{ value : 50 }();
        assertTrue(
            asset.balanceOf(acc2) == 2,
            "Didn't add the shares"
        );
        assertTrue(
            address(asset).balance == 75,
            "Didn't add the funds to the balance"
        );
    }

    function testSellAsset() public {
        vm.deal(acc3, 25);
        vm.startPrank(acc3);
        asset.buy{ value : 25 }();
        assertTrue(
            acc3.balance == 0,
            "Account not emptied properly"
        );
        assertTrue(
            address(asset).balance == 50,
            "Asset cash position not correct"
        );
        assertTrue(
            asset.balanceOf(acc3) == 1,
            "Balance not correct"
        );
        assertTrue(
            asset.pricePerShare() == 25,
            "Balance not correct"
        );

        // 1 share = 25
        asset.sell(1);
        vm.stopPrank();
        assertTrue(
            asset.balanceOf(acc3) == 0,
            "Balance of account not reduced"
        );
        assertTrue(
            acc3.balance == 25,
            "Asset didn't send the money"
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
