// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IERC4907.sol";
import "./interfaces/IDCL.sol";
import "./DCL.sol";

contract Rental is Ownable, Pausable {
    uint256 private feePercent;
    uint64 public maxIndate;
    uint256 private feeBalance;

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        
        _unpause();
    }

    constructor(uint256 _feePercent) {
        maxIndate = 365 days;
        feePercent = _feePercent;
    }

    struct RentalOffer {
        uint256 tokenId;
        address owner;
        uint256 dailyRentPrice;
        uint64 rentalDuration;
        uint64 rentalExpiration;
        bool isActive;
    }
    mapping(uint256 => RentalOffer) public rentalOffers;

    event RentalOfferCreated(uint256 tokenId, address owner, uint256 dailyRentPrice, uint64 rentalDuration);
    event RentalOfferAccepted(uint256 tokenId, address renter, uint256 totalRent, uint64 rentalDuration);
    event RentalOfferCancelled(uint256 tokenId, address owner);

    function isDecentralandLand(uint256 tokenId, address nftAddress) public view returns (bool) {
        try DCL(nftAddress).updateOperator(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function supports4907(uint256 tokenId, address nftAddress) public view returns (bool) {
        try IERC4907(nftAddress).userOf(tokenId) returns (address) {
            return true;
        } catch {
            return false;
        }
    }

    function createRentalOffer(uint256 tokenId, uint256 dailyRentPrice, uint64 rentalDuration, address nftAddress) public whenNotPaused {
        require(ERC721(nftAddress).ownerOf(tokenId) == msg.sender, "Rental: Not the owner of the token");
        require(!rentalOffers[tokenId].isActive, "Rental: Rental offer already exists");
        require(IERC4907(nftAddress).userOf(tokenId) == address(0), "Rental: NFT should not already have an existing renter");

        RentalOffer memory newRentalOffer = RentalOffer({
            tokenId: tokenId,
            owner: msg.sender,
            dailyRentPrice: dailyRentPrice,
            rentalDuration: rentalDuration,
            rentalExpiration: 0,
            isActive: true
        });

        rentalOffers[tokenId] = newRentalOffer;

        emit RentalOfferCreated(tokenId, msg.sender, dailyRentPrice, rentalDuration);
    }

    function acceptRentalOffer(uint256 tokenId, address nftAddress, uint64 daysToRent) public payable whenNotPaused {
        RentalOffer storage rentalOffer = rentalOffers[tokenId];

        require(rentalOffer.isActive, "Rental: Rental offer not active");
        require(daysToRent > 0 && daysToRent <= rentalOffer.rentalDuration, "Rental: Invalid number of days to rent");
        require(daysToRent * rentalOffer.dailyRentPrice <= msg.value, "Rental: Rent price not met");

        uint256 totalRent = daysToRent * rentalOffer.dailyRentPrice;
        uint64 expires = uint64(block.timestamp) + (daysToRent * 1 days);

        // If DCL
        bool isDcl = isDecentralandLand(tokenId, nftAddress);
        if(isDcl) {
            IDCL(nftAddress).setUpdateOperator(tokenId, msg.sender);
        } else {
            bool nftSupports4907 = supports4907(tokenId, nftAddress);
            if(nftSupports4907) {
                IERC4907(nftAddress).setUser(tokenId, msg.sender, expires);
            }
        }

        uint256 feeAmount = (totalRent * feePercent) / 100;
        uint256 nftOwnerAmount = msg.value - feeAmount;
        feeBalance += feeAmount;

        (bool sent, ) = rentalOffer.owner.call{value: nftOwnerAmount}("");
        require(sent, "Rental: Failed to send Ether to the owner");

        rentalOffer.isActive = false;
        rentalOffer.rentalExpiration = expires;

        emit RentalOfferAccepted(tokenId, msg.sender, feeAmount, daysToRent * 1 days);
    }

    function claimExpiredRental(uint256 tokenId, address nftAddress) public {
        RentalOffer storage rentalOffer = rentalOffers[tokenId];

        require(rentalOffer.rentalExpiration != 0 && rentalOffer.rentalExpiration < block.timestamp, "Rental: Rental has not expired yet");

        bool isDcl = isDecentralandLand(tokenId, nftAddress);
        if (isDcl) {
            IDCL(nftAddress).setUpdateOperator(tokenId, rentalOffer.owner);
        }
    }

    function cancelRentalOffer(uint256 tokenId) public whenNotPaused {
        RentalOffer storage rentalOffer = rentalOffers[tokenId];

        require(rentalOffer.isActive, "Rental: Rental offer not active");
        require(rentalOffer.owner == msg.sender, "Rental: Not the owner of the token");

        rentalOffer.isActive = false;

        emit RentalOfferCancelled(tokenId, msg.sender);
    }

    function withdrawFees() public onlyOwner {
        require(feeBalance > 0, "Rental: No balance to withdraw");

        (bool sent, ) = owner().call{value: feeBalance}("");
        require(sent, "Rental: Failed to send Ether to the owner");
        feeBalance = 0;
    }

    function getFeeBalance() public onlyOwner view returns (uint256){
        return feeBalance;
    }
}
