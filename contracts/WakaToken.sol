// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WakaToken is ERC20('WakaSwap', 'WAKA'), Ownable {

    address public exchangeAirdropCampaign;
    address public treasuryAddress;

    // mints 400,000 WAKA for Exchange airdrop & 275,685 for Treasury >
    constructor (address _exchange, address _treasury) public {

        exchangeAirdropCampaign = _exchange;
        treasuryAddress = _treasury;

        mintTo(exchangeAirdropCampaign, 400000000000000000000000);
        mintTo(treasuryAddress, 275685000000000000000000);
    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mintTo(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
