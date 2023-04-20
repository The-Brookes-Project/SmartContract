const Rental = artifacts.require("Rental");
const ERC721 = artifacts.require("ERC721Mock");

const { expect } = require("chai");
const { BN, ether } = require("@openzeppelin/test-helpers");

contract("Rental", function (accounts) {
  const [renter, addr1, renter2] = accounts;
  let rental, erc721, tokenId;

  beforeEach(async () => {
    erc721 = await ERC721.new("Sample Token", "ERC");
    tokenId = 1;
    await erc721.mint(addr1, tokenId);

    rental = await Rental.new();
    await rental.initialize();

    await erc721.approve(rental.address, tokenId, { from: addr1 });
  });

  describe("createRentalOffer", () => {
    it("should create a rental offer", async () => {
      const rentPrice = ether("1");
      const rentalDuration = new BN(7 * 24 * 60 * 60);

      await rental.createRentalOffer(tokenId, rentPrice, rentalDuration, erc721.address, { from: addr1 });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.tokenId.toString()).to.equal(tokenId.toString());
      expect(rentalOffer.owner).to.equal(addr1);
      expect(rentalOffer.rentPrice.toString()).to.equal(rentPrice.toString());
      expect(rentalOffer.rentalDuration.toString()).to.equal(rentalDuration.toString());
      expect(rentalOffer.isActive).to.equal(true);
    });
  });

  describe("acceptRentalOffer", () => {
    it("should accept a rental offer", async () => {
      const rentPrice = ether("1");
      const rentalDuration = new BN(7 * 24 * 60 * 60);

      await rental.createRentalOffer(tokenId, rentPrice, rentalDuration, erc721.address, { from: addr1 });

      await rental.acceptRentalOffer(tokenId, erc721.address, { from: renter, value: rentPrice });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.isActive).to.equal(false);
    });
  });

  describe("cancelRentalOffer", () => {
    it("should cancel a rental offer", async () => {
      const rentPrice = ether("1");
      const rentalDuration = new BN(7 * 24 * 60 * 60);

      await rental.createRentalOffer(tokenId, rentPrice, rentalDuration, erc721.address, { from: addr1 });

      await rental.cancelRentalOffer(tokenId, { from: addr1 });

      const rentalOffer = await rental.rentalOffers(tokenId);

      expect(rentalOffer.isActive).to.equal(false);
    });
  });
});
