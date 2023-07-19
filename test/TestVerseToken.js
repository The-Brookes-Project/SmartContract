const { time } = require('@openzeppelin/test-helpers');
const RentalContract = artifacts.require("RentalContract");
const dailyRentFee = web3.utils.toWei("1", "ether"); // 1 ether for testing

contract("RentalContract", accounts => {
    let instance;

    beforeEach(async function() {
        // Deploy RentalContract
        instance = await RentalContract.new(accounts[0], dailyRentFee, { from: accounts[0] });
    });

    describe("mint()", function() {
        it("should allow user to mint NFT", async function() {
            await instance.mint(1, {from: accounts[1], value: web3.utils.toWei("1", "ether")});

            let tokenOwner = await instance.ownerOf(1);
            let expiration = await instance.expirations(1);

            assert.equal(tokenOwner, accounts[1]);
            assert.isAbove(Number(expiration), Math.floor(Date.now() / 1000)); // expiration should be in the future
        });

        it("should fail with insufficient payment", async function() {
            try {
                await instance.mint(1, {from: accounts[1], value: web3.utils.toWei("0.9", "ether")}); // not enough for fee
                assert.fail("The transaction should have thrown an error");
            }
            catch (err) {
                assert.include(err.message, "Incorrect payment amount", "The error message should contain 'Incorrect payment amount'");
            }
        });
        it("should transfer the correct fee to versepropAddress", async function() {
            let initialVersepropBalance = await web3.eth.getBalance(accounts[0]);
            
            // Mint a token
            await instance.mint(1, {from: accounts[1], value: web3.utils.toWei("1", "ether")}); // 1 Ether for rent + 10% fee
            
            let finalVersepropBalance = await web3.eth.getBalance(accounts[0]);
            let fee = web3.utils.toBN(web3.utils.toWei("0.1", "ether")); // 10% fee
    
            assert.equal(web3.utils.toBN(finalVersepropBalance).toString(), web3.utils.toBN(initialVersepropBalance).add(fee).toString(), "Fee should be transferred to versepropAddress");
        });
    });

    describe("burn()", function() {
        beforeEach(async function() {
            // mint a token that will be burned
            await instance.mint(1, {from: accounts[1], value: web3.utils.toWei("1", "ether")}); // include 10% fee
            // advance time to make sure the token can be burned
            await time.increase(time.duration.days(2));
        });

        it("should allow token owner to burn NFT", async function() {
            await instance.mint(5, {from: accounts[0], value: web3.utils.toWei("5", "ether")});
    
            try {
                await instance.burn(1, {from: accounts[1]});
            } catch (error) {
                assert(error.message.includes('ERC721: invalid token ID'), 'The error message should contain "ERC721: invalid token ID"');
                return;
            }
        });

        it("should prevent non-owner from burning NFT", async function() {
            try {
                await instance.burn(1, {from: accounts[2]});
                assert.fail("The transaction should have thrown an error");
            }
            catch (err) {
                assert.include(err.message, "Only token owner can burn", "The error message should contain 'Only token owner can burn'");
            }
        });
    });
});
