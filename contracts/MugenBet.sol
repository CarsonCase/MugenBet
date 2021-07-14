//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

import "./Betting.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MugenBet is Betting, Ownable{
    uint constant private OPTIONS = 2;
    uint immutable private reductionRate;
    bytes32[] games;

    event NewGame(bytes32);
    event GameOver(bytes32);

    constructor(uint _r) Ownable(){
        reductionRate = _r;
    }

    /**
    * @dev newGame function called by owner to create a game, and push it to array
     */
    function newGame()external onlyOwner{
        bytes32 key = _newBook(address(this), OPTIONS, reductionRate);
        games.push(key);
        emit NewGame(key);
    }

    /**
    * @dev settleGame called with a game's results
    * @param _winner is the index of the winner of the game
     */
    function settleGame(bytes32 _book, uint _winner)external onlyOwner{
        callBet(_book, _winner);
        emit GameOver(_book);
    }

    /**
    * @dev returns the first two amounts of a game for frontend
    * @param _game is the game id
    * @return both the amounts
     */
    function getFirsttwoAmounts(bytes32 _game)external view returns(uint,uint){
        return(books[_game].optionsAmounts[0], books[_game].optionsAmounts[1]);
    }
}