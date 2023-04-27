const Rental = artifacts.require("Rental");
const ERC721 = artifacts.require("ERC721Mock");

const { expect } = require("chai");
const { BN, ether } = require("@openzeppelin/test-helpers");

contract("Rental", function (accounts) {
  const [owner, addr1, renter, renter2] = accounts;
  let rental, erc721, tokenId;

  beforeEach(async () => {
    erc721 = await ERC721.new("Sample NFT Real Estate", "ERC");
    tokenId = 1;
    await erc721.mint(addr1, tokenId);

    rental = await Rental.new(new BN(5), {from: owner});
    await erc721.approve(rental.address, tokenId, { from: addr1 });
  });

  describe("createRentalOffer", () => {
    it("should create a rental offer", async () => {
      const dailyRentPrice = ether("0.1");
      const rentalDuration = new BN(7 * 24 * 60 * 60);

      await rental.createRentalOffer(tokenId, dailyRentPrice, rentalDuration, erc721.address, { from: addr1 });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.tokenId.toString()).to.equal(tokenId.toString());
      expect(rentalOffer.owner).to.equal(addr1);
      expect(rentalOffer.dailyRentPrice.toString()).to.equal(dailyRentPrice.toString());
      expect(rentalOffer.rentalDuration.toString()).to.equal(rentalDuration.toString());
      expect(rentalOffer.isActive).to.equal(true);
    });
  });

  describe("acceptRentalOffer", () => {
    it("should accept a rental offer", async () => {
      const dailyRentPrice = ether("0.1");
      const totalRent = ether("0.7");
      const rentalDuration = new BN(7 * 24 * 60 * 60);
      const rentDays = new BN(7);

      await rental.createRentalOffer(tokenId, dailyRentPrice, rentalDuration, erc721.address, { from: addr1 });

      await rental.acceptRentalOffer(tokenId, erc721.address, rentDays, { from: renter, value: totalRent });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.isActive).to.equal(false);
    });
  });

  describe("cancelRentalOffer", () => {
    it("should cancel a rental offer", async () => {
      const dailyRentPrice = ether("0.1");
      const rentalDuration = new BN(7 * 24 * 60 * 60);

      await rental.createRentalOffer(tokenId, dailyRentPrice, rentalDuration, erc721.address, { from: addr1 });

      await rental.cancelRentalOffer(tokenId, { from: addr1 });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.isActive).to.equal(false);
    });
  });

  describe("claimExpiredRental", () => {
    it("should allow the owner to claim expired rental", async () => {
      const dailyRentPrice = ether("0.1");
      const rentalDuration = new BN(1); // 1 day
      const rentDays = new BN(1);

      await rental.createRentalOffer(tokenId, dailyRentPrice, rentalDuration, erc721.address, { from: addr1 });
      await rental.acceptRentalOffer(tokenId, erc721.address, rentDays, { from: renter, value: dailyRentPrice });

      // Simulate the passage of 2 days
      await web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_increaseTime",
          params: [2 * 24 * 60 * 60],
          id: 0,
        },
        () => {}
      );
      await web3.currentProvider.send(
        {
          jsonrpc: "2.0",
          method: "evm_mine",
          id: 1,
        },
        () => {}
      );

      await rental.claimExpiredRental(tokenId, erc721.address, { from: addr1 });
      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.isActive).to.equal(false);
    });
  });
});
