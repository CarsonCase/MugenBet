MugenBet
========

Components
----------
* Books: An object describing options to bet on, and the current amounts bet. This is the information a book has:  
```
    struct book{
        address bookie;
        uint reductionRate;
        uint[] optionsAmounts;
        uint[] optionsDebt;
        uint[] betTickets;                  //NEW -> For Frontend
        uint optionsCount;
        uint totalBets;
        bool complete;
        uint winner;
    }
```
* Bet Tickets: ERC-721 NFTs representing the right to collect on a bet if the outcome matches your option. Bet ticket's ID's are tied to the following struct by the `betTicketFromNFT` mapping:  
```
    struct betTicket{
        bytes32 book;
        uint option;
        uint payout;
    }
```
* books: A mapping tying a bytes32 hash to a book
* games: An array of book IDs, games open to bet on

Functionality Needed on Frontend
--------------------------------
For the frontend the following must be implemented: 
* The most recent games are fetched from `games` and displayed with players (NOTE: For now display players as "team A" and "team B" cooresponding to option 0 and 1 in parameters. I will give an API endpoint to fetch player names from later)
* Also display the odds for each "team". Odds are retrieved from the `getOdds()` function. This actually returns the payout, but you can simply divide by the amount betting to get odds. This is on a BONDING CURVE. So the odds depend on how much someone bets, pick a number or a percent of the total bets in the pool to use by default. But if time allows, have a form where users can enter a number and it will call `getOdds` to see what the odds are for their bet.
* Allow users to place bets on the games. Call `placeBet()` for this.
* When a game is over, (book will show complete true) allow users who's bet ticket's option matches the winner in book to collect on the game by calling `settleBet()`