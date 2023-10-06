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

    uint _deadline = block.timestamp + 3601;

    function setUp() public {
        marketPlace = new MarketPlace();
        // Deploy NFT contract
        nft = new NFT("IDAN_NFT", "IDAN", "baseUri");

        (userA, keyUserA) = mkaddr("USERA");
        (userB, keyUserB) = mkaddr("USERB");

        nft.mintTo(userA);

        newOrder = MarketPlace.Order({
            owner: address(0),
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

    function testFailTokenHasBeenListed() external {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
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
    }

    function testIfSignatureIsValid() public {
        switchSigner(userA);
        nft.approve(address(marketPlace), 1);
        newOrder.deadline = uint88(block.timestamp + 36001);
        newOrder.signature = constructSig(
            newOrder.tokenAddress,
            newOrder.tokenId,
            newOrder.nftPrice,
            newOrder.deadline,
            newOrder.owner,
            keyUserB
        );
        vm.expectRevert("Invalid Signature");
        marketPlace.putNFTForSale(
            newOrder.signature,
            newOrder.tokenId,
            newOrder.tokenAddress,
            newOrder.nftPrice,
            newOrder.deadline
        );
    }
}
