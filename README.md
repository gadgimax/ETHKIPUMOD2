# Module 2  
## Auction Smart Contract

This repository contains a smart contract for a simple auction. The contract was deployed from my address on the **Sepolia** testnet and includes all required and advanced functionalities.

---

## Required Links

- **Verified Contract on Sepolia**:  
  [[https://sepolia.etherscan.io/address/0x...](https://sepolia.etherscan.io/address/0xe03e89a08368Ace5c82D3ab2efC1472d0198B976#code)]

- **Public GitHub Repository**:  
  [https://github.com/gadgimax/ETHKIPUMOD2](https://github.com/gadgimax/ETHKIPUMOD2) 

---

## Implemented Features

### Constructor  
Initializes the auction with the duration.

### Place Bid Function  
Allows users to place bids if:

- The auction is still active  
- The bid is **at least 5% higher** than the current highest bid  

➡Emits the `NewBid` event.

### Get Winner  
Returns the current leading bidder and their bid.

### Get Bids  
Returns the list of all bidders and their latest bid values.

### Finalize Auction  
When the auction ends:

- Deposits are returned to all bidders (the winner only receives excess deposits)
- A **2% commission** is deducted  
- Only the auction creator (owner) can finalize the auction  

➡Emits the `AuctionEnded` event.

### Deposit Management  
- All bids must be backed by ETH deposited into the contract  
- Each deposit is tied to the bidder’s address

### Partial Refund (Advanced)  
During the auction, users can withdraw the **excess** ETH above their current bid..

---

## Events

- `event NewBid(address indexed bidder, uint amount);`  
- `event AuctionEnded(address indexed winner, uint amount);`

---

## Security and Reliability

- Uses modifiers to enforce permissions and state:
  - `onlyOwner`, `auctionActive`, `auctionEnded`, `notReturned`
- Auction time auto-extends by 10 minutes if a valid bid arrives near the end
- Minimum bid increment is enforced

---

## Technical Documentation

- All public functions and key variables are documented with **NatSpec** comments (`///`)  
- The contract is readable and fully self-contained  
- Internal logic is encapsulated; non-public elements are marked `private`

---

## Notes

- **The winner also receives any excess ETH they deposited** when the auction ends.  
  Without this, earlier bids from the winner would remain stuck in the contract.

- **Only the latest (i.e., highest) bid is stored per user** to minimize on-chain data.  
  Previous bids can still be retrieved from the `NewBid` event logs if needed.
  
## Project Checklist

- [x] Deployed on **Sepolia**  
- [x] Verified with source code visible  
- [x] Public on GitHub  

---
