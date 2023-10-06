// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {MarketPlace} from "../src/MarketPlace.sol";
import {NFT} from "../src/NFT.sol";
import "./Helper.sol";

contract TestHelpers is Helpers {
    NFT private nft;
    MarketPlace private marketPlace;

    address userA;
    address userB;

    uint256 keyUserA;
    uint256 keyUserB;

    MarketPlace.Order newOrder;

    event NFTLISTED(uint orderId);
    event NFTSOLD(uint orderId);
    uint currentOrderId;

    uint deadline = block.timestamp + 3601;

    function setUp() public {
        marketPlace = new MarketPlace();
        // Deploy NFT contract
        nft = new NFT("IDAN_NFT", "IDAN", "baseUri");

        (userA, keyUserA) = mkaddr("USERA");
        (userB, keyUserB) = mkaddr("USERB");

        nft.mintTo(userA);

        newOrder = MarketPlace.Order({
            owner: userA,
            tokenAddress: address(nft),
            tokenId: 1,
            nftPrice: 0.1 ether,
            deadline: 0,
            signature: bytes(""),
            active: false
        });
    }

    function test_AccountListingOwnsNFT() external {
        switchSigner(userB);
        vm.expectRevert("Not Owner");
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
    }

    function test_IsNFTApproved() external {
        switchSigner(userA);
        vm.expectRevert("Please approve NFT to be sold");
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
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
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
    }

    function test_DeadlineMustBeOneHourAhead() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        vm.expectRevert("Deadline must be one hour later than present time");
        newOrder.deadline = block.timestamp + 100;
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
    }

    function test_TokenHasBeenListed() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        vm.expectRevert("token has been listed");
        newOrder.deadline = block.timestamp + 36001;
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
        bytes32 hashedNft = marketPlace.hashedListing(
            newOrder.tokenAddress,
            newOrder.tokenId
        );
        assertTrue(marketPlace.hashedToken[hashedNft]);
    }

    // function test_CreateListing() public {
    //     //List NFT
    //     vm.startPrank(0x9d4eF81F5225107049ba08F69F598D97B31ea644);
    //     bytes memory sig = constructSig(address(nft), token_id, 1e15, nftOwner);
    //     vm.expectEmit(true, false, false, false);
    //     // The event we expect
    //     emit NFTLISTED(1);
    //     marketPlace.putNFTForSale(sig, token_id, address(nft), 1e15, deadline);
    //     orderId = 1;
    //     vm.stopPrank();

    //     vm.warp(block.timestamp + 3800);
    //     //Buy NFT
    //     vm.startPrank(0x1b6e16403b06a51C42Ba339E356a64fE67348e92);
    //     vm.deal(0x1b6e16403b06a51C42Ba339E356a64fE67348e92, 1e18);
    //     vm.expectEmit(true, false, false, false);
    //     // The event we expect
    //     emit NFTSOLD(1);
    //     marketPlace.buyNFT{value: 0.001 ether}(orderId);
    //     vm.stopPrank();
    // }
}
