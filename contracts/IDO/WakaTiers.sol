// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;
import "../utils/SafeMath.sol";
import "../utils/ERC20.sol";
import "../utils/UpgradableOwnable.sol";


contract WakaTiers is UpgradableOwnable {

    using SafeMath for uint;

    struct UserInfo {
        uint staked;
        uint stakedTime;
    }

    uint constant MAX_NUM_TIERS = 10;
    uint8 currentMaxTier = 4;

    mapping(address => UserInfo) public userInfo;
    uint[MAX_NUM_TIERS] public tierPrice;
    uint[MAX_NUM_TIERS] public tierWeight;

    uint[] public withdrawFeePercent;
    IERC20 public WAKA;

    bool public canEmergencyWithdraw;
    address public feeRecipient;

    event Staked(address indexed user, uint amount);
    event Withdrawn(address indexed user, uint indexed amount, uint fee);
    event EmergencyWithdrawn(address indexed user, uint amount);

    function __WakaTiers_init(IERC20 _wakaTokenAddress, address _wakaFeeRecipient, address _governor) public initializer {
        __Governable_init_unchained(_governor);

        WAKA = _wakaTokenAddress;

        tierPrice[1] = 2000e18;
        tierPrice[2] = 5000e18;
        tierPrice[3] = 10000e18;
        tierPrice[4] = 20000e18;

        tierWeight[1] = 1;
        tierWeight[2] = 2;
        tierWeight[3] = 5;
        tierWeight[4] = 10;

        withdrawFeePercent.push(30);
        withdrawFeePercent.push(25);
        withdrawFeePercent.push(20);
        withdrawFeePercent.push(10);
        withdrawFeePercent.push(5);
        withdrawFeePercent.push(0);
        feeRecipient = _wakaFeeRecipient;
    }

    function deposit(uint _amount) external {
        userInfo[msg.sender].staked = userInfo[msg.sender].staked.add(_amount);
        userInfo[msg.sender].stakedTime = block.timestamp;

        WAKA.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    function withdraw(uint _amount) external {
        UserInfo storage user = userInfo[msg.sender];
        require(user.staked >= _amount, "not enough amount to withdraw");

        uint fee = calculateWithdrawFee(msg.sender, _amount);
        user.staked = user.staked.sub(_amount);

        WAKA.transfer(feeRecipient, fee);
        WAKA.transfer(msg.sender, _amount.sub(fee));
        emit Withdrawn(msg.sender, _amount, fee);
    }

    function updateEmergencyWithdrawStatus(bool _status) external governance {
        canEmergencyWithdraw = _status;
    }

    function emergencyWithdraw() external {
        require(canEmergencyWithdraw, "function disabled");
        UserInfo storage user = userInfo[msg.sender];
        require(user.staked > 0, "nothing to withdraw");

        uint _amount = user.staked;
        user.staked = 0;

        WAKA.transfer(msg.sender, _amount);
        emit EmergencyWithdrawn(msg.sender, _amount);
    }

    function updateTierPrice(uint8 _tierId, uint _amount) external governance {
        require(_tierId > 0 && _tierId <= MAX_NUM_TIERS, "invalid _tierId");
        tierPrice[_tierId] = _amount;
        if (_tierId > currentMaxTier) {
            currentMaxTier = _tierId;
        }
    }

    function updateTierWeight(uint8 _tierId, uint _amount) external governance {
        require(_tierId > 0 && _tierId <= MAX_NUM_TIERS, "invalid _tierId");
        tierWeight[_tierId] = _amount;
        if (_tierId > currentMaxTier) {
            currentMaxTier = _tierId;
        }
    }

    function updateWithdrawFee(uint _key, uint _percent) external governance {
        require(_percent < 100, "too high percent");
        withdrawFeePercent[_key] = _percent;
    }

    function getUserTier(address _userAddress) external view returns(uint8 res) {
        for (uint8 i = 1; i <= MAX_NUM_TIERS; i++) {
            if(tierPrice[i] == 0 || userInfo[_userAddress].staked < tierPrice[i]) {
                return res;
            }

            res = i;
        }
    }

    function calculateWithdrawFee(address _userAddress, uint _amount) public view returns(uint) {
        UserInfo storage user = userInfo[_userAddress];
        require(user.staked >= _amount, "not enough amount to withdraw");

        if(block.timestamp < user.stakedTime.add(10 days)) {
            return _amount.mul(withdrawFeePercent[0]).div(100); //30%
        }

        if(block.timestamp < user.stakedTime.add(20 days)) {
            return _amount.mul(withdrawFeePercent[1]).div(100); //25%
        }

        if(block.timestamp < user.stakedTime.add(30 days)) {
            return _amount.mul(withdrawFeePercent[2]).div(100); //20%
        }

        if(block.timestamp < user.stakedTime.add(60 days)) {
            return _amount.mul(withdrawFeePercent[3]).div(100); //10%
        }

        if(block.timestamp < user.stakedTime.add(90 days)) {
            return _amount.mul(withdrawFeePercent[4]).div(100); //5%
        }

        return _amount.mul(withdrawFeePercent[5]).div(100);
    }
}
