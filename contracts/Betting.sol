// SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
* @title Betting
* @author Carson Case: carsonpcase@gmail.com
* @notice A contract for betting complete with a bookies reduction rate.
* The contract can issue "books" of bets which their bookies profit off of. And users can bet on.
* The ID of a book is emited as an event and a bet ticket is issued as an NFT with incremental interger IDs
 */
contract Betting is ERC721{
    uint public constant oneHundredPercent = 10000;
    uint latestId = 0;
    
    struct betTicket{
        bytes32 book;
        uint option;
        uint payout;
    }

    struct book{
        address bookie;
        uint reductionRate;
        uint[] optionsAmounts;
        uint optionsCount;
        uint totalBets;
        bool complete;
        uint winner;
    }



    mapping(uint => betTicket) public betTicketFromNFT;
    mapping(bytes32 => book) public books;

    event NewBet(uint, address, bytes32);
    event NewBook(address, bytes32);
    /// @dev constructor
    constructor()ERC721("Betting Ticket","BET"){}

    /**
    * @dev function to place a bet. Anyone can call on any book as long as the option is included in the book
    * @param _book is the book hash
    * @param _option is the option to bet on
     */
    function placeBet(bytes32 _book, uint _option) external payable{
        _issueBet(msg.sender, _book, _option, msg.value);
    }

    /**
    * @dev function to collect on a won bet
    * @param ticket is the NFT id to turn in for the winnings
     */
    function settleBet(uint ticket) external{
        require(books[betTicketFromNFT[ticket].book].complete, "Bet must be complete");
        require(books[betTicketFromNFT[ticket].book].winner == betTicketFromNFT[ticket].option, "Must have bet on the winner");
        transferFrom(msg.sender, address(this), ticket);
        _burn(ticket);
        payable(msg.sender).transfer(betTicketFromNFT[ticket].payout);
    }

    /**
    * @dev Function to call the winner of a bet. Only callable by bookie.
    * @param _book to call
    * @param _winner must be within options
    */
    function callBet(bytes32 _book, uint _winner)external{
        require(_winner < books[_book].optionsCount, "Winner must be within options");
        require(msg.sender == books[_book].bookie, "Only the bookie can settle the bet");
        books[_book].winner = _winner;
        books[_book].complete = true;
        uint bookieFee =    ((oneHundredPercent - books[_book].reductionRate) * 
                            books[_book].totalBets) / 
                            oneHundredPercent;
        payable(books[_book].bookie).transfer(bookieFee);
    }

    /**
    * @dev fundBet  */
    function fundBet(bytes32 _book) external payable{
        require(msg.sender == books[_book].bookie, "Only the bookie can provide the books funding");
        _mint(msg.sender, latestId);
        uint sum = 0;
        uint each = msg.value / books[_book].optionsCount;
        require(each > 1, "Must send enough wei to fund each option");
        for(uint i = 0; i < books[_book].optionsCount - 1; i++){
            sum += each;
            _issueBet(msg.sender, _book, i, each);
        }
        //For the last option send what's left of msg.value in case of rounding errors
        _issueBet(msg.sender, _book, books[_book].optionsCount, msg.value - sum);
    }

    function getOdds(bytes32 _book, uint _option, uint _amount) public view returns(uint){
        book storage b = books[_book];
        return(
            (b.reductionRate/2) * 
            (((_amount + b.optionsAmounts[_option]) * _amount) / 
            books[_book].totalBets) / 
            oneHundredPercent
        );
    }

    function _newBook(address _bookie, uint _numOptions, uint reductionRate) internal {
        require(reductionRate < oneHundredPercent, "Reduction rate cannot be more than 100%");
        require(_numOptions > 1, "Must have more than 1 option to bet on");
        book memory b = book(_bookie, reductionRate, new uint[](0), _numOptions, 0, false, 0);
        bytes32 key = keccak256(abi.encodePacked(_bookie, reductionRate, _numOptions,msg.sender,block.timestamp));
        require(books[key].bookie == address(0), "book already exists at this key, you're likely trying to create multiple of the same books in one tx. Don't do this.");
        books[key] = b;
        emit NewBook(_bookie, key);
    }

    function _issueBet(address _to, bytes32 _book, uint _option, uint _amount) private{
            require(books[_book].optionsCount > _option, "bet must be within options");
        _mint(_to, latestId);
        betTicketFromNFT[latestId] = betTicket(
            _book,
            _option,
            getOdds(_book,_option,_amount)
        );
        books[_book].totalBets += _amount;
        books[_book].optionsAmounts[_option] += _amount;
        emit NewBet(latestId, _to, _book);
        latestId++;

    }

}
