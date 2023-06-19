// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CollateralizedRental is Ownable {
    struct Rental {
        address payable owner;
        address payable renter;
        address tokenAddress;
        uint256 tokenId;
        uint256 collateral;
        uint256 dailyFee;
        uint256 rentStart;
        uint256 rentalDays;
        uint256 maxRentalDays;
        bool isRented;
    }

    mapping(address => mapping(uint256 => Rental)) public rentals;

    function listForRent(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _collateral,
        uint256 _maxRentalDays,
        uint256 _dailyFee
    ) public {
        IERC721 nftContract = IERC721(_nftAddress);
        require(
            nftContract.ownerOf(_tokenId) == msg.sender,
            "Not owner of NFT"
        );
        nftContract.transferFrom(msg.sender, address(this), _tokenId);
        rentals[_nftAddress][_tokenId] = Rental(
            payable(msg.sender),
            payable(address(0)),
            _nftAddress,
            _tokenId,
            _collateral,
            _dailyFee,
            0,
            0,
            _maxRentalDays,
            false
        );
    }

    function rent(
        address _nftAddress,
        uint256 _tokenId,
        uint256 _rentalDays
    ) public payable {
        IERC721 nftContract = IERC721(_nftAddress);
        Rental storage rental = rentals[_nftAddress][_tokenId];
        require(
            _rentalDays <= rental.maxRentalDays,
            "Rental days exceed max rental days"
        );
        uint256 totalFee = rental.dailyFee * _rentalDays;
        require(
            msg.value == rental.collateral + totalFee,
            "Must send correct collateral amount and rental fee"
        );
        require(rental.isRented == false, "NFT already rented");
        rental.owner.transfer(totalFee); // transfer rental fee to owner
        rental.isRented = true;
        rental.rentStart = block.timestamp; // rental starts now
        rental.renter = payable(msg.sender); // set the renter
        rental.rentalDays = _rentalDays; // set rental days
        nftContract.transferFrom(address(this), msg.sender, _tokenId);
        nftContract.approve(address(this), _tokenId); // approve the contract to claim back the NFT
    }

    function returnRental(address _nftAddress, uint256 _tokenId) public {
        IERC721 nftContract = IERC721(_nftAddress);
        Rental storage rental = rentals[_nftAddress][_tokenId];
        require(rental.isRented == true, "NFT is not rented");
        require(
            msg.sender == rental.renter,
            "Only the renter can return the NFT"
        );
        nftContract.transferFrom(msg.sender, rental.owner, _tokenId); // transfer NFT back to owner
        payable(msg.sender).transfer(rental.collateral);
        delete rentals[_nftAddress][_tokenId];
    }

    function cancelListing(address _nftAddress, uint256 _tokenId) public {
        IERC721 nftContract = IERC721(_nftAddress);
        Rental storage rental = rentals[_nftAddress][_tokenId];
        require(
            msg.sender == rental.owner,
            "Only the owner can claim back the NFT"
        );
        require(rental.isRented == false, "NFT is already rented");
        nftContract.transferFrom(rental.renter, rental.owner, _tokenId); // transfer NFT back to owner
        delete rentals[_nftAddress][_tokenId];
    }

    function claimBack(address _nftAddress, uint256 _tokenId) public {
        IERC721 nftContract = IERC721(_nftAddress);
        Rental storage rental = rentals[_nftAddress][_tokenId];
        require(
            msg.sender == rental.owner,
            "Only the owner can claim back the NFT"
        );
        require(rental.isRented == true, "NFT is not rented");
        require(
            rental.rentStart + rental.rentalDays * 1 days < block.timestamp,
            "Rental period has not ended yet"
        );
        nftContract.transferFrom(rental.renter, rental.owner, _tokenId); // transfer NFT back to owner
        delete rentals[_nftAddress][_tokenId];
    }

    // Fee withdrawal function
    function withdraw(address payable _to) public onlyOwner {
        require(_to != address(0), "Invalid address");
        _to.transfer(address(this).balance);
    }

    function claimCollateral(
        address _nftAddress,
        uint256 _tokenId
    ) public onlyOwner {
        Rental storage rental = rentals[_nftAddress][_tokenId];
        require(rental.isRented == true, "NFT is not rented");
        require(
            rental.rentStart + rental.rentalDays * 1 days + 10 days <
                block.timestamp,
            "Collateral can be claimed only 10 days after rental period has ended"
        );
        payable(rental.owner).transfer(rental.collateral);
        delete rentals[_nftAddress][_tokenId];
    }
}
