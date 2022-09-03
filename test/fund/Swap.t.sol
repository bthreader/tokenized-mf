// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {GenericTest} from "../GenericTest.sol";

import {OffChainFund} from "../../src/fund/OffChainFund.sol";
import {Swap} from "../../src/fund/Swap.sol";

contract SwapTest is Test, GenericTest {
    OffChainFund public _fundA;
    OffChainFund public _fundB;
    Swap public swap;

    constructor () {    
        
        //
        // Fund A
        //
        
        vm.startPrank(acc1);
        _fundA = new OffChainFund();
        _fundA.addAccountant(acc1);
        _fundA.setNav(100);
        _fundA.addVerifier(acc1);

        // Verify
        _fundA.addVerified(acc2);
        _fundA.addVerified(acc3);
        vm.stopPrank();

        // Give acc2 10 shares
        vm.deal(acc2, 1000);
        vm.prank(acc2);
        _fundA.placeBuyNavOrder{ value : 1000 }();

        //
        // Fund B
        //

        vm.startPrank(acc1);
        _fundB = new OffChainFund();
        _fundB.addAccountant(acc1);
        _fundB.setNav(100);
        _fundB.addVerifier(acc1);

        // Verify
        
        _fundB.addVerified(acc2);
        _fundB.addVerified(acc3);
        vm.stopPrank();

        // Give acc3 10 shares
        vm.deal(acc3, 1000);
        vm.prank(acc3);
        _fundB.placeBuyNavOrder{ value : 1000 }();

        swap = new Swap({assetA : _fundA, assetB : _fundB});
        vm.startPrank(acc1);
        _fundA.addVerified(address(swap));
        _fundB.addVerified(address(swap));
        vm.stopPrank();
    }

    function testSwap() public {
        // Approve the swap contract for 10 shares
        vm.prank(acc2);
        _fundA.approve({spender : address(swap), amount : 10});

        // Sanity check
        assertTrue(
            _fundA.allowance({owner : acc2, spender : address(swap)}) == 10,
            "Allowance not given"
        );

        vm.prank(acc3);
        _fundB.approve({spender : address(swap), amount : 10});

        // Use swap contract to send those shares to acc3
        swap.swap({
            counterpartyA : acc2, 
            counterpartyB : acc3, 
            amountAssetA : 10,
            amountAssetB : 10
        });

        assertTrue(
            _fundA.allowance({owner : acc2, spender : address(swap)}) == 0,
            "Allowance not spent"
        );

        assertTrue(
            _fundA.balanceOf(acc3) == 10,
            "Funds not moved over"
        );

        assertTrue(
            _fundB.allowance({owner : acc3, spender : address(swap)}) == 0,
            "Allowance not spent"
        );

        assertTrue(
            _fundB.balanceOf(acc2) == 10,
            "Funds not moved over"
        );
    }
}