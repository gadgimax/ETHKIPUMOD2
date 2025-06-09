// SPDX-License-Identifier: MIT
pragma solidity >0.8.0;

/// @title ETHKIPU Auction Contract
/// @author Gaston Gorosito
/// @notice This contract allows users to participate in a timed auction with deposit-based bidding
/// @dev Includes deposit tracking, refund logic, and bid extension within the final minutes
contract Auction {
    /// @notice Address of the auction creator
    address private owner;
    
    /// @notice Address of the current highest bidder
    address private highestBidder;

    /// @notice List of all bidders (to return deposits later)
    address[] private bidders;

    /// @notice Auction start time (Unix timestamp)
    uint256 private startTime;

    /// @notice Auction end time (Unix timestamp)
    uint256 private endTime;

    /// @notice Minimum required percentage increase over the last bid
    uint256 private constant MIN_INCREMENT_PERCENTAGE = 5;

    /// @notice Time extension applied if a bid is placed within the last 10 minutes
    uint256 private constant EXTENSION_TIME = 10 minutes;

    /// @notice Highest bid so far
    uint256 private highestBid;

    /// @notice Mapping to track deposits per bidder
    mapping(address => uint256) private deposits;

    /// @notice Mapping to track bids per bidder
    mapping(address => uint256) private bids;

    /// @notice Tracks if a bidder has already placed a bid
    mapping(address => bool) private hasBid;

    /// @notice Flag to avoid duplicate refunding
    bool private depositsReturned;

    /// @notice Emitted when a new highest bid is placed
    event NewBid(address indexed bidder, uint256 amount);

    /// @notice Emitted when the auction ends
    event AuctionEnded(address indexed winner, uint256 amount);

    /// @dev Ensures that only the owner can call the function
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can execute this");
        _;
    }

    /// @dev Ensures the auction is still active
    modifier auctionActive() {
        require(block.timestamp <= endTime, "The auction has ended.");
        _;
    }

    /// @dev Ensures the auction has ended
    modifier auctionEnded() {
        require(block.timestamp >= endTime, "The auction has not ended yet.");
        _;
    }

    /// @dev Ensures deposits haven't already been returned
    modifier notReturned() {
        require(!depositsReturned, "Deposits have already been returned.");
        _;
    }

    /// @notice Initializes the auction
    /// @param duration Duration of the auction in seconds
    constructor(uint256 duration) {
        owner = msg.sender;
        startTime = block.timestamp;
        endTime = block.timestamp + duration;
    }

    /// @notice Place a new bid in the auction
    function placeBid() external payable auctionActive {
        uint value = msg.value;
        require(value > 0, "Bid must be bigger than zero.");

        address sender = msg.sender; 
        // Calculate total deposit after current transfer
        uint256 newDeposit = deposits[sender] + value; 

        // Check if the new bid is at least MIN_INCREMENT_PERCENTAGE higher than the current highest
        if (highestBid > 0) {
            uint256 minBid = highestBid + (highestBid * MIN_INCREMENT_PERCENTAGE) / 100;
            require(
                value > minBid,
                string.concat(
                    "You must outbid the current highest by at least 5%."
                )
            );
        }

        // Add sender to bidder list if it's their first bid
        if (!hasBid[sender]) {
            hasBid[sender] = true;
            bidders.push(sender);
        }

        // Update deposit and bid tracking
        deposits[sender] = newDeposit;
        bids[sender] = value;

        // Update highest bid and bidder
        highestBid = value;
        highestBidder = sender;

        // Extend auction if bid placed close to the end
        if (endTime - block.timestamp <= EXTENSION_TIME) {
            endTime += EXTENSION_TIME;
        }

        emit NewBid(sender, value);
    }

    /// @notice Struct representing a bid
    struct Bid {
        address bidder;
        uint256 amount;
    }

    /// @notice Get the current winning bid
    /// @return A Bid struct with the winner and the bid amount
    function getWinner() external view returns (Bid memory) {
        return Bid(highestBidder, highestBid);
    }

    /// @notice Get all submitted bids
    /// @return An array of Bid structs with each bidder’s latest bid
    function getBids() external view returns (Bid[] memory) {
        uint256 count = bidders.length;
        address bidder;
        Bid[] memory list = new Bid[](count);

        // Build list of bids
        for (uint256 i = 0; i < count; i++) {
            bidder = bidders[i];
            list[i] = Bid(bidder, bids[bidder]);
        }

        return list;
    }

    /// @dev Internal function to refund deposits (excess only for winner) minus 2% fee
    function returnDeposits() private {
        // Declare local variables outside for loop
        uint256 count = bidders.length;
        address bidder;
        uint256 deposit;
        uint256 fee;
        uint256 amountToReturn;
        bool sent;
        
        for (uint256 i = 0; i < count; i++) {
            bidder = bidders[i];
            deposit = deposits[bidder];

            // Winner only gets excess refunded
            if (bidder == highestBidder) {
                deposit = deposit - bids[bidder];
            }

            if (deposit > 0) {
                // Apply 2% fee on the excess
                fee = (deposit * 2) / 100;
                amountToReturn = deposit - fee;

                deposits[bidder] = 0;

                // Send the ETH back
                (sent, ) = bidder.call{value: amountToReturn}("");
                require(sent, "Error returning ETH");
            }
        }

        depositsReturned = true;
    }

    /// @notice Finalizes the auction and refunds participants
    function finalizeAuction() external onlyOwner auctionEnded notReturned {
        returnDeposits();
        emit AuctionEnded(highestBidder, highestBid);
    }

    /// @notice Allows a user to withdraw the excess of their deposit during the auction
    function withdrawExcess() external auctionActive {
        address sender = msg.sender;
        uint256 deposit = deposits[sender];
        uint256 bid = bids[sender];

        // Ensure there's excess to withdraw
        require(deposit > bid, "No excess to withdraw.");

        uint256 excess = deposit - bid;
        deposits[sender] = bid;

        // Send the excess back
        (bool sent, ) = sender.call{value: excess}("");
        require(sent, "Error sending ETH");
    }
}
