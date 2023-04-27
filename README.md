# Verseprop Marketplace Smart Contract - Truffle Project

## Sepolia Contract Addresses:
- Marketplace: 0xfA2d157C5A604C0d83b492e5769eBB747D140bd4
- Rental: 0x0c566A1eb7d47861B176e39e05109b85e6385CD2


## Purpose
The purpose of this smart contract is to achieve the flow of the digital `land` (NFT) agency marketplace logic.

### Running tests:
```
truffle test
```

### Deploying the contract locally:
```
truffle migrate
```

## Stack
Solidity, Truffle

## Functions
### addAdvisor
Add an advisor of the platform to handle the negotiation process between the buyers and the sellers.
This function is only callable by the contract owner.

### deleteAdvisor
Delete the registered advisor.
This function is only callable by the contract owner.

### isAdvisor
Check if a wallet is a registered advisor's.

### sendOffer
Send an offer to the buyer and the seller.
This function is only callable by the advisor.

### cancelOffer
Cancel an offer which was already sent.
This function is only callable by the advisor.

### offerData
Get an offer with its id.

### acceptOffer
Accept an offer.
This function is only callable by the buyer or seller of the offer.
Before the buyer and the seller accept the offer they are supposed to approve the land/token for the contract.
When both the buyer and the seller accept the offer, the `land` is transferred from the seller to the buyer,
97.5% amount of the token is transferred from the buyer to the seller 
and 2.5% amount of the token is transferred from the buyer to the contract owner for the profit.

### declineOffer
Decline an offer.
This function is only callable by the buyer or seller of the offer.
