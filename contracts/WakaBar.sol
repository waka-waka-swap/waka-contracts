// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// WakaBar is the coolest bar in town. You come in with some Waka, and leave with more! The longer you stay, the more Waka you get.
//
// This contract handles swapping to and from xWaka, WakaSwap's staking token.
contract WakaBar is ERC20("WakaBar", "xWAKA"){
    using SafeMath for uint256;
    IERC20 public waka;

    // Define the Waka token contract
    constructor(IERC20 _waka) public {
        waka = _waka;
    }

    // Enter the bar. Pay some WAKAs. Earn some shares.
    // Locks Waka and mints xWaka
    function enter(uint256 _amount) public {
        // Gets the amount of Waka locked in the contract
        uint256 totalWaka = waka.balanceOf(address(this));
        // Gets the amount of xWaka in existence
        uint256 totalShares = totalSupply();
        // If no xWaka exists, mint it 1:1 to the amount put in
        if (totalShares == 0 || totalWaka == 0) {
            _mint(msg.sender, _amount);
        } 
        // Calculate and mint the amount of xWaka the Waka is worth. The ratio will change overtime, as xWaka is burned/minted and Waka deposited + gained from fees / withdrawn.
        else {
            uint256 what = _amount.mul(totalShares).div(totalWaka);
            _mint(msg.sender, what);
        }
        // Lock the Waka in the contract
        waka.transferFrom(msg.sender, address(this), _amount);
    }

    // Leave the bar. Claim back your WAKAs.
    // Unclocks the staked + gained Waka and burns xWaka
    function leave(uint256 _share) public {
        // Gets the amount of xWaka in existence
        uint256 totalShares = totalSupply();
        // Calculates the amount of Waka the xWaka is worth
        uint256 what = _share.mul(waka.balanceOf(address(this))).div(totalShares);
        _burn(msg.sender, _share);
        waka.transfer(msg.sender, what);
    }
}