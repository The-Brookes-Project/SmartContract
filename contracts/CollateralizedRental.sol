// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract CollateralizedRental {
    struct Rental {
        address payable owner;
        address payable renter;
        uint256 collateral;
        uint256 dailyFee;
        uint256 rentStart;
        uint256 rentalDays;
        bool isRented;
    }

    mapping(address => mapping(uint256 => Rental)) public rentals;
    IERC721 public nftContract;

    constructor(address _nftAddress) {
        nftContract = IERC721(_nftAddress);
    }

    function listForRent(uint256 _tokenId, uint256 _collateral, uint256 _rentalDays, uint256 _dailyFee) public {
        require(nftContract.ownerOf(_tokenId) == msg.sender, "Not owner of NFT");
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        rentals[msg.sender][_tokenId] = Rental(payable(msg.sender), payable(address(0)), _collateral, _dailyFee, 0, _rentalDays, false);
    }

    function rent(uint256 _tokenId, address _owner) public payable {
        Rental storage rental = rentals[_owner][_tokenId];
        uint256 totalFee = rental.dailyFee * rental.rentalDays;
        require(msg.value == rental.collateral + totalFee, "Must send correct collateral amount and rental fee");
        require(rental.isRented == false, "NFT already rented");
        rental.owner.transfer(totalFee); // transfer rental fee to owner
        rental.isRented = true;
        rental.rentStart = block.timestamp; // rental starts now
        rental.renter = payable(msg.sender); // set the renter
        nftContract.approve(msg.sender, _tokenId); // approve the renter to take the NFT
    }

    function claimRental(uint256 _tokenId, address _owner) public {
        Rental storage rental = rentals[_owner][_tokenId];
        require(rental.isRented == true, "NFT is not rented");
        require(nftContract.getApproved(_tokenId) == msg.sender, "You must be approved for this NFT");
        nftContract.transferFrom(address(this), msg.sender, _tokenId); // transfer NFT to renter
    }

    function returnRental(uint256 _tokenId, address _owner) public {
        Rental storage rental = rentals[_owner][_tokenId];
        require(rental.isRented == true, "NFT is not rented");
        require(rental.rentStart + rental.rentalDays * 1 days >= block.timestamp, "Rental period has not ended yet");
        require(msg.sender == rental.renter, "Only the renter can return the NFT");
        nftContract.transferFrom(msg.sender, _owner, _tokenId); // transfer NFT back to owner
        payable(msg.sender).transfer(rental.collateral);
        delete rentals[_owner][_tokenId];
    }

    function claimBack(uint256 _tokenId, address _owner) public {
        require(msg.sender == _owner, "Only the owner can claim back the NFT");
        Rental storage rental = rentals[_owner][_tokenId];
        require(rental.isRented == true, "NFT is not rented");
        require(rental.rentStart + rental.rentalDays * 1 days < block.timestamp, "Rental period has not ended yet");
        nftContract.transferFrom(msg.sender, _owner, _tokenId); // transfer NFT back to owner
        delete rentals[_owner][_tokenId];
    }
}