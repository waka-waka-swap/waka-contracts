// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WakaToken is ERC20('Waka.Finance', 'WAKA'), Ownable {

    address public marketing; // ~2.5%
    address public ido; // 2.5%
    address public devFund; // 10%
    address public initialLPReward; // 5%
    address public ecosystemGrants; // 2.5%



    // pre-mints 25% of the token supply
    constructor (address _marketing, address _ido, address _devFund, address _initialLPReward, address _grants) public {

        marketing = _marketing;
        ido = _ido;
        devFund = _devFund;
        initialLPReward = _initialLPReward;
        ecosystemGrants = _grants;

        mintTo(marketing, 253696000000000000000000);
        mintTo(ido, 250000000000000000000000);
        mintTo(devFund, 1000000000000000000000000);
        mintTo(initialLPReward, 500000000000000000000000);
        mintTo(ecosystemGrants, 250000000000000000000000);

    }

    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner.
    function mintTo(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}
