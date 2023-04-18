const { expect } = require('chai');
const { BN, ether, expectEvent, expectRevert } = require('@openzeppelin/test-helpers');
const Marketplace = artifacts.require('Marketplace');
const ERC721Mock = artifacts.require('ERC721Mock');
const ERC20Mock = artifacts.require('ERC20Mock');

contract('Marketplace', function ([owner, newAdvisor, seller, buyer, anotherAccount]) {
  beforeEach(async function () {
    this.marketplace = await Marketplace.new({ from: owner });
    this.erc721 = await ERC721Mock.new("ERC721Mock", "E721", { from: owner });
    this.erc20 = await ERC20Mock.new("ERC20Mock", "E20", 18, { from: owner });

    await this.marketplace.addAdvisor(newAdvisor, { from: owner });

    await this.erc721.mint(seller, 1, { from: owner });
    await this.erc20.mint(buyer, ether('10'), { from: owner });
  });

  describe('addAdvisor', function () {
    it('should add a new advisor', async function () {
      await this.marketplace.addAdvisor(anotherAccount, { from: owner });

      expect(await this.marketplace.isAdvisor(anotherAccount)).to.be.true;
    });

    it('reverts when not called by the owner', async function () {
      await expectRevert(this.marketplace.addAdvisor(anotherAccount, { from: anotherAccount }), 'Ownable: caller is not the owner');
    });
  });

  describe('deleteAdvisor', function () {
    it('should remove an advisor', async function () {
      await this.marketplace.deleteAdvisor(newAdvisor, { from: owner });

      expect(await this.marketplace.isAdvisor(newAdvisor)).to.be.false;
    });

    it('reverts when not called by the owner', async function () {
      await expectRevert(this.marketplace.deleteAdvisor(newAdvisor, { from: anotherAccount }), 'Ownable: caller is not the owner');
    });
  });

  describe('sendOffer', function () {
    it('should send an offer', async function () {
      const tx = await this.marketplace.sendOffer(
        seller, buyer, this.erc721.address, 1, this.erc20.address, ether('1'), { from: newAdvisor }
      );
  
      const offerId = tx.logs[0].args._offerId;
      const offer = await this.marketplace.offerData(offerId);
  
      expect(offer.seller).to.equal(seller);
      expect(offer.buyer).to.equal(buyer);
      expect(offer.collection).to.equal(this.erc721.address);
      expect(offer.assetId).to.be.bignumber.equal(new BN(1));
      expect(offer.token).to.equal(this.erc20.address);
      expect(offer.price).to.be.bignumber.equal(ether('1'));
    });
  
    it('reverts when not called by an advisor', async function () {
      await expectRevert(
        this.marketplace.sendOffer(
          seller, buyer, this.erc721.address, 1, this.erc20.address, ether('1'), { from: anotherAccount }
        ),
        'The caller must be the Advisor.'
      );
    });
  });
  
  describe('acceptOffer', function () {
    beforeEach(async function () {
      const tx = await this.marketplace.sendOffer(
        seller, buyer, this.erc721.address, 1, this.erc20.address, ether('1'), { from: newAdvisor }
      );
  
      this.offerId = tx.logs[0].args._offerId;
    });
  
    it('should accept an offer', async function () {
      await this.marketplace.acceptOffer(this.offerId, { from: seller });
  
      const offer = await this.marketplace.offerData(this.offerId);
  
      expect(offer.status).to.be.bignumber.equal(new BN(0));
      expect(offer.sellerAcceptStatus).to.be.bignumber.equal(new BN(1));
      expect(offer.buyerAcceptStatus).to.be.bignumber.equal(new BN(0));
    });
  
    it('reverts when not called by the seller or buyer', async function () {
      await expectRevert(
        this.marketplace.acceptOffer(this.offerId, { from: anotherAccount }),
        'The caller must be the seller/buyer.'
      );
    });
  });
  
  describe('cancelOffer', function () {
    beforeEach(async function () {
      const tx = await this.marketplace.sendOffer(
        seller, buyer, this.erc721.address, 1, this.erc20.address, ether('1'), { from: newAdvisor }
      );
  
      this.offerId = tx.logs[0].args._offerId;
    });
  
    it('should cancel an offer', async function () {
      await this.marketplace.cancelOffer(this.offerId, { from: newAdvisor });
  
      const offer = await this.marketplace.offerData(this.offerId);
  
      expect(offer.status).to.be.bignumber.equal(new BN(2));
    });
  
    it('reverts when not called by an advisor', async function () {
      await expectRevert(
        this.marketplace.cancelOffer(this.offerId, { from: anotherAccount }),
        'The caller must be the Advisor.'
      );
    });
  });
  
  describe('declineOffer', function () {
    beforeEach(async function () {
      const tx = await this.marketplace.sendOffer(
        seller, buyer, this.erc721.address, 1, this.erc20.address, ether('1'), { from: newAdvisor }
      );
  
      this.offerId = tx.logs[0].args._offerId;
    });
  
    it('should decline an offer by the seller', async function () {
      await this.marketplace.declineOffer(this.offerId, { from: seller });
  
      const offer = await this.marketplace.offerData(this.offerId);
  
      expect(offer.status).to.be.bignumber.equal(new BN(3));
      expect(offer.sellerAcceptStatus).to.be.bignumber.equal(new BN(2));
    });
  
    it('should decline an offer by the buyer', async function () {
      await this.marketplace.declineOffer(this.offerId, { from: buyer });
  
      const offer = await this.marketplace.offerData(this.offerId);
  
      expect(offer.status).to.be.bignumber.equal(new BN(3));
      expect(offer.buyerAcceptStatus).to.be.bignumber.equal(new BN(2));
    });
  
    it('reverts when not called by the seller or buyer', async function () {
      await expectRevert(
        this.marketplace.declineOffer(this.offerId, { from: anotherAccount }),
        'The caller must be the seller/buyer.'
      );
    });
  });
  
});
