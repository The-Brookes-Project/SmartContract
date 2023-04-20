// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "./interfaces/IERC4907.sol";

contract Rental is Ownable, ReentrancyGuardUpgradeable {
    uint256 private fee;
    uint64 public maxIndate;

    function initialize() public initializer {
        __ReentrancyGuard_init();
        maxIndate = 365 days;
        fee = 2500;
    }

    struct RentalOffer {
        uint256 tokenId;
        address owner; 
        uint256 rentPrice;  
        uint64 rentalDuration;
        bool isActive;
    }

    mapping(uint256 => RentalOffer) public rentalOffers;

    event RentalOfferCreated(uint256 tokenId, address owner, uint256 rentPrice, uint64 rentalDuration);
    event RentalOfferAccepted(uint256 tokenId, address renter, uint256 rentPrice, uint64 rentalDuration);
    event RentalOfferCancelled(uint256 tokenId, address owner);

    function createRentalOffer(uint256 tokenId, uint256 rentPrice, uint64 rentalDuration, address nftAddress) public {
        require(ERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Rental: Not the owner of the token");
        require(!rentalOffers[tokenId].isActive, "Rental: Rental offer already exists");
        require(IERC4907(nftAddress).userOf(tokenId) == address(0), "Rental: NFT should not already have an existing renter");

        RentalOffer memory newRentalOffer = RentalOffer({
            tokenId: tokenId,
            owner: msg.sender,
            rentPrice: rentPrice,
            rentalDuration: rentalDuration,
            isActive: true
        });

        rentalOffers[tokenId] = newRentalOffer;

        emit RentalOfferCreated(tokenId, msg.sender, rentPrice, rentalDuration);
    }

    function acceptRentalOffer(uint256 tokenId, address nftAddress) public payable {
        RentalOffer storage rentalOffer = rentalOffers[tokenId];

        require(rentalOffer.isActive, "Rental: Rental offer not active");
        require(msg.value == rentalOffer.rentPrice, "Rental: Rent price not met");

        uint64 expires = uint64(block.timestamp) + rentalOffer.rentalDuration;
        IERC4907(nftAddress).setUser(tokenId, msg.sender, expires);

        (bool sent, ) = rentalOffer.owner.call{value: msg.value}("");
        require(sent, "Rental: Failed to send Ether");

        rentalOffer.isActive = false;

        emit RentalOfferAccepted(tokenId, msg.sender, rentalOffer.rentPrice, rentalOffer.rentalDuration);
    }

    function cancelRentalOffer(uint256 tokenId) public {
        RentalOffer storage rentalOffer = rentalOffers[tokenId];

        require(rentalOffer.isActive, "Rental: Rental offer not active");
        require(rentalOffer.owner == msg.sender, "Rental: Not the owner of the token");

        rentalOffer.isActive = false;

        emit RentalOfferCancelled(tokenId, msg.sender);
    }
}
