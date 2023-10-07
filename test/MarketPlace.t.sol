// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {NFT} from "../src/NFT.sol";
import "./Helper.sol";
import "forge-std/console.sol";

contract TestHelpers is Helpers {
    NFT private nft;
    MarketPlace private marketPlace;

    address userA;
    address userB;

    uint256 privKeyA;
    uint256 privKeyB;

    MarketPlace.Order newOrder;

    event NFTLISTED(uint orderId);
    event NFTSOLD(uint orderId);

    uint _deadline = block.timestamp + 3601;

    function setUp() public {
        marketPlace = new MarketPlace();
        // Deploy NFT contract
        nft = new NFT("IDAN_NFT", "IDAN", "baseUri");

        (userA, privKeyA) = mkaddr("USERA");
        (userB, privKeyB) = mkaddr("USERB");

        newOrder = MarketPlace.Order({
            owner: userA,
            tokenAddress: address(nft),
            tokenId: 1,
            nftPrice: 0.1 ether,
            deadline: 0,
            signature: bytes(""),
            active: false
        });
        nft.mintTo(userA);
    }

    function test_AccountListingOwnsNFT() external {
        switchSigner(userB);
        vm.expectRevert("Not Owner");
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    function test_IsNFTApproved() external {
        switchSigner(userA);
        vm.expectRevert("Please approve NFT to be sold");
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    // function test_tokenAddressIsNotEOA() external {
    //     switchSigner(userA);
    //     nft.approve(address(marketPlace), 1);
    //     newOrder.tokenAddress = address(
    //         0x1b6e16403b06a51C42Ba339E356a64fE67348e92
    //     );
    //     vm.expectRevert("Token address is an EOA");
    //     marketPlace.putNFTForSale(
    //         newOrder.signature,
    //         newOrder.tokenId,
    //         newOrder.tokenAddress,
    //         newOrder.nftPrice,
    //         newOrder.deadline
    //     );
    // }

    function test_PriceMustBeGreatherThanZero() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        vm.expectRevert("Price must be greater than zero");
        newOrder.nftPrice = 0;
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    function test_DeadlineMustBeOneHourAhead() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        vm.expectRevert("Deadline must be one hour later than present time");
        newOrder.deadline = block.timestamp + 100;
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    function testFailTokenHasBeenListed() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        newOrder.deadline = block.timestamp + 36001;
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    function testIfSignatureIsInValid() public {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        newOrder.active = true;
        newOrder.deadline = block.timestamp + 36001;
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyB
        );
        vm.expectRevert("Invalid Signature");

        marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
    }

    function test_InactiveListing() external {
        switchSigner(userA);
        newOrder.deadline = block.timestamp + 36001;
        nft.approve(address(marketPlace), 1);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyA
        );
        uint order_id = marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        marketPlace.editOrder(order_id, 0.1 ether, false);
        vm.expectRevert("Listing not active");
        marketPlace.buyNFT{value: 0.1 ether}(1);
    }

    function test_ExpertDeadlinePassed() external {
        switchSigner(userA);
        newOrder.active = true;
        newOrder.deadline = block.timestamp + 36001;
        nft.approve(address(marketPlace), 1);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyA
        );
        uint order_id = marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        switchSigner(userB);
        vm.expectRevert("Deadline passed");
        marketPlace.buyNFT{value: 0.1 ether}(order_id);
    }

    function test_IncorrectValue() external {
        switchSigner(userA);
        newOrder.active = true;
        newOrder.deadline = block.timestamp + 120 minutes;
        nft.approve(address(marketPlace), 1);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyA
        );
        uint order_id = marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        switchSigner(userB);
        vm.expectRevert("Incorrect Eth Value");
        vm.warp(1641070800);
        marketPlace.buyNFT{value: 0.2 ether}(order_id);
    }

    function test_BuyNFT() external {
        switchSigner(userA);
        newOrder.deadline = block.timestamp + 120 minutes;
        nft.approve(address(marketPlace), 1);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyA
        );
        uint order_id = marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        switchSigner(userB);
        vm.warp(1641070800);
        marketPlace.buyNFT{value: 0.1 ether}(order_id);
        assertEq(nft.ownerOf(order_id), userB);
    }

    function test_TestIfOrderExistBeforeEditing() external {
        switchSigner(userA);
        vm.expectRevert("Order Doesn't Exist");
        marketPlace.editOrder(1, 0.1 ether, true);
    }

    function test_TestIfOrderOwnerBeforeEditing() external {
        switchSigner(userA);
        newOrder.deadline = block.timestamp + 120 minutes;
        nft.approve(address(marketPlace), 1);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            privKeyA
        );
        uint order_id = marketPlace.putNFTForSale(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.signature
        );
        switchSigner(userB);
        vm.expectRevert("Not Owner");
        marketPlace.editOrder(order_id, 0.1 ether, true);
    }
}
