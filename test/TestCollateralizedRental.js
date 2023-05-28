const { time } = require('@openzeppelin/test-helpers');
const CollateralizedRental = artifacts.require("CollateralizedRental");
const ERC721Mock = artifacts.require('ERC721Mock');

contract("CollateralizedRental", accounts => {
    let instance;
    let tokenInstance;
    let tokenAddress;

    beforeEach(async function() {
        // Deploy MockERC721Token contract for testing
        tokenInstance = await ERC721Mock.new("ERC721Mock", "E721", { from: accounts[0] });
        tokenAddress = tokenInstance.address;

        // Deploy CollateralizedRental contract
        instance = await CollateralizedRental.new();

        // Mint some ERC721 tokens for testing
        await tokenInstance.mint(accounts[0], 1);
        await tokenInstance.mint(accounts[0], 2);
        await tokenInstance.mint(accounts[1], 3);
        await tokenInstance.setApprovalForAll(instance.address, 1, {from: accounts[0]});
        await tokenInstance.setApprovalForAll(instance.address, 1, {from: accounts[1]});
    });

    describe("listForRent()", function() {
        it("should allow owner to list NFT for rent", async function() {
            await instance.listForRent(tokenAddress, 1, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});

            let rental = await instance.rentals(tokenAddress, 1);

            assert.equal(rental.owner, accounts[0]);
            assert.equal(rental.collateral.toString(), web3.utils.toWei("1", "ether"));
            assert.equal(rental.maxRentalDays.toString(), '5');
            assert.equal(rental.dailyFee.toString(), web3.utils.toWei("0.02", "ether"));
            assert.equal(rental.isRented, false);
        });
    });

    describe("rent()", function() {
        it("should allow a user to rent an NFT", async function() {
            await instance.listForRent(tokenAddress, 2, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});
            await instance.rent(tokenAddress, 2, 3, {from: accounts[1], value: web3.utils.toWei("1.06", "ether")});

            let rental = await instance.rentals(tokenAddress, 2);

            assert.equal(rental.isRented, true);
            assert.equal(rental.renter, accounts[1]);
            assert.equal(rental.rentalDays.toString(), '3');
        });
    });

    describe("returnRental()", function() {
        it("should allow a user to return an NFT", async function() {
            await instance.listForRent(tokenAddress, 2, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});
            await instance.rent(tokenAddress, 2, 3, {from: accounts[1], value: web3.utils.toWei("1.06", "ether")});
            await instance.returnRental(tokenAddress, 2, {from: accounts[1]});

            let rental = await instance.rentals(tokenAddress, 2);

            assert.equal(rental.renter, '0x0000000000000000000000000000000000000000');
        });
    });

    describe("claimBack()", function() {
        it("should allow owner to claim back NFT after rental period", async function() {
            await instance.listForRent(tokenAddress, 2, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});
            await instance.rent(tokenAddress, 2, 3, {from: accounts[1], value: web3.utils.toWei("1.06", "ether")});
            
            // Make sure the rental period has passed
            await time.increase(time.duration.days(4));
            
            await instance.claimBack(tokenAddress, 2, {from: accounts[0]});

            let rental = await instance.rentals(tokenAddress, 2);

            assert.equal(rental.owner, '0x0000000000000000000000000000000000000000');
        });
    });
    
    describe("withdraw()", function() {
        it("should allow the contract owner to withdraw the balance", async function() {
            await instance.listForRent(tokenAddress, 2, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});
            await instance.rent(tokenAddress, 2, 3, {from: accounts[1], value: web3.utils.toWei("1.06", "ether")});
            
            let initialBalance = await web3.eth.getBalance(accounts[0]);
            await instance.withdraw(accounts[0], {from: accounts[0]});
            let finalBalance = await web3.eth.getBalance(accounts[0]);

            assert.isAbove(Number(finalBalance), Number(initialBalance), "Withdraw failed");
        });
    });

    describe("claimCollateral()", function() {
        it("should allow contract owner to claim collateral 10 days after rental period", async function() {
            await instance.listForRent(tokenAddress, 2, web3.utils.toWei("1", "ether"), 5, web3.utils.toWei("0.02", "ether"), {from: accounts[0]});
            await instance.rent(tokenAddress, 2, 3, {from: accounts[1], value: web3.utils.toWei("1.06", "ether")});
            
            // Make sure the rental period + 10 days have passed
            await time.increase(time.duration.days(14));
            
            await instance.claimCollateral(tokenAddress, 2, {from: accounts[0]});
            let rental = await instance.rentals(tokenAddress, 2);

            assert.equal(rental.owner, '0x0000000000000000000000000000000000000000');
        });
    });
});
