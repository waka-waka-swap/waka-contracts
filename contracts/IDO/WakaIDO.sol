// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.6.12;

import "./WakaTiers.sol";
import "../utils/SafeERC20.sol";

contract WakaIDO is ReentrancyGuard {
    uint constant MAX_NUM_TIERS = 4;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 firstRoundAmountToClaim;
        uint256 secondRoundAmountToClaim;
        uint256 thirdRoundAmountToClaim;
        uint8 tier;
        bool registered;
        bool claimed;
    }

    address public adminAddress;
    IERC20 public raisingToken;
    IERC20 public offeringToken;
    WakaTiers public tiersContract;

    uint256 public registrationStartBlock;
    uint256 public firstRoundStartBlock;
    uint256 public firstRoundEndBlock;
    uint256 public secondRoundEndBlock;
    uint256 public holdTokensTillBlock;

    // total amount of raising tokens need to be raised
    uint256 public raisingAmount;
    // total amount of offeringToken that will offer
    uint256 public offeringAmount;
    // address => amount
    mapping (address => UserInfo) public userInfo;
    // participators
    address[] public addressList;

    uint[MAX_NUM_TIERS + 1] public numberOfUsersByTier;

    uint256 public offeringAmountFirstRoundTotal;
    uint256 public offeringAmountSecondRoundTotal;
    uint256 public offeringAmountThirdRoundTotal;

    event Deposit(address indexed user, uint256 amount, uint8 round);
    event Claim(address indexed user, uint256 offeringAmount);

    constructor(
        IERC20 _raisingToken,
        IERC20 _offeringToken,
        uint256 _registrationStartBlock,
        uint256 _firstRoundStartBlock,
        uint256 _firstRoundEndBlock,
        uint256 _secondRoundEndBlock,
        uint256 _holdTokensTillBlock,
        uint256 _offeringAmount,
        uint256 _raisingAmount,
        address _adminAddress,
        address _tiersContractAddress
    ) public {
        require(_registrationStartBlock < _firstRoundStartBlock, 'the first round block number is less than the registration start');
        require(_firstRoundStartBlock < _firstRoundEndBlock, 'the first round end number is less than the start');
        require(_firstRoundEndBlock <= _secondRoundEndBlock, 'the first round end block is more than the second round start');
        require(_secondRoundEndBlock <= _holdTokensTillBlock, 'the second round end block is more than the hold till tokens block number');
        raisingToken = _raisingToken;
        offeringToken = _offeringToken;
        registrationStartBlock = _registrationStartBlock;
        firstRoundStartBlock = _firstRoundStartBlock;
        firstRoundEndBlock = _firstRoundEndBlock;
        secondRoundEndBlock = _secondRoundEndBlock;
        holdTokensTillBlock = _holdTokensTillBlock;
        offeringAmount = _offeringAmount;
        raisingAmount = _raisingAmount;
        adminAddress = _adminAddress;
        tiersContract = WakaTiers(_tiersContractAddress);
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "not an admin");
        _;
    }

    modifier onlyRegistered() {
        require (userInfo[msg.sender].registered, 'the user has not been registered');
        _;
    }

    modifier onlyNotClaimed() {
        require (!userInfo[msg.sender].claimed, 'the user has already claimed');
        _;
    }

    modifier notZeroAmount(uint256 _amount) {
        require (_amount > 0, 'amount has to be greater than 0');
        _;
    }

    function register() public {
        require (block.number > registrationStartBlock, 'registration didn`t start');
        require (block.number < firstRoundStartBlock, 'registration finished');
        uint8 currentTier = tiersContract.getUserTier(msg.sender);
        require (currentTier != 0, 'the user has no tier');
        if (userInfo[msg.sender].registered) {
            numberOfUsersByTier[userInfo[msg.sender].tier] = numberOfUsersByTier[userInfo[msg.sender].tier].sub(1);
        }
        userInfo[msg.sender].tier = currentTier;
        userInfo[msg.sender].registered = true;
        numberOfUsersByTier[currentTier] = numberOfUsersByTier[currentTier].add(1);
    }

    function getTierWeight(uint8 _tier) public view returns(uint256) {
        return numberOfUsersByTier[_tier].mul(tiersContract.tierWeight(_tier));
    }

    function getTierAllocation(uint8 _tier) public view returns(uint256) {
        uint currentTierWeight = getTierWeight(_tier);
        uint summaryWeight = currentTierWeight;
        for (uint8 i = 1; i <= MAX_NUM_TIERS; i++) {
            if (i == _tier) {
                continue;
            }
            summaryWeight = summaryWeight.add(getTierWeight(i));
        }
        return currentTierWeight.mul(offeringAmount).div(summaryWeight);
    }

    function getTokensLeftInPool() public view returns(uint256) {
        return offeringAmount
        .sub(offeringAmountFirstRoundTotal)
        .sub(offeringAmountSecondRoundTotal)
        .sub(offeringAmountThirdRoundTotal);
    }

    function getSecondRoundAllocation(uint256 _amount) public pure returns(uint256) {
        return _amount.div(2);
    }

    function getUserAllocation(address _user) public view returns(uint256) {
        if (userInfo[_user].tier == 0) {
            return 0;
        }
        return getTierAllocation(userInfo[_user].tier).div(numberOfUsersByTier[userInfo[_user].tier]);
    }

    function depositFirstRound(uint256 _amountToPay) public onlyRegistered notZeroAmount(_amountToPay) {
        require (block.number > firstRoundStartBlock && block.number < firstRoundEndBlock, 'not the first round time');
        uint256 userAllocation = getUserAllocation(msg.sender);
        UserInfo storage user = userInfo[msg.sender];
        uint256 offeringTokenLeftToBuy = userAllocation.sub(user.firstRoundAmountToClaim);
        require (offeringTokenLeftToBuy > 0, 'no tokens left to buy');
        uint256 amountToDeposit = _amountToPay;
        uint256 offeringTokenReceived = _amountToPay.mul(offeringAmount).div(raisingAmount);
        if (offeringTokenLeftToBuy < offeringTokenReceived) {
            offeringTokenReceived = offeringTokenLeftToBuy;
            amountToDeposit = offeringTokenLeftToBuy.mul(raisingAmount).div(offeringAmount);
        }
        raisingToken.safeTransferFrom(address(msg.sender), address(this), amountToDeposit);
        if (user.firstRoundAmountToClaim == 0) {
            addressList.push(address(msg.sender));
        }
        user.firstRoundAmountToClaim = user.firstRoundAmountToClaim.add(offeringTokenReceived);
        offeringAmountFirstRoundTotal = offeringAmountFirstRoundTotal.add(offeringTokenReceived);
        emit Deposit(msg.sender, amountToDeposit, 1);
    }

    function depositSecondRound(uint256 _amountToPay) public onlyRegistered notZeroAmount(_amountToPay) {
        require (block.number > firstRoundEndBlock && block.number < secondRoundEndBlock, 'not the second round time');
        uint256 userAllocation = getSecondRoundAllocation(getUserAllocation(msg.sender));
        UserInfo storage user = userInfo[msg.sender]; // TODO: fix storage
        uint256 offeringTokenLeftToBuy = userAllocation.sub(user.secondRoundAmountToClaim);
        uint256 tokensLeftInPool = getTokensLeftInPool();
        require (offeringTokenLeftToBuy > 0 && tokensLeftInPool > 0, 'no tokens left to buy');
        uint256 amountToDeposit = _amountToPay;
        uint256 offeringTokenReceived = _amountToPay.mul(offeringAmount).div(raisingAmount);

        if (offeringTokenLeftToBuy < offeringTokenReceived) {
            offeringTokenReceived = offeringTokenLeftToBuy;
        }

        if (tokensLeftInPool < offeringTokenReceived) {
            offeringTokenLeftToBuy = tokensLeftInPool;
        }
        amountToDeposit = offeringTokenReceived.mul(raisingAmount).div(offeringAmount);

        raisingToken.safeTransferFrom(address(msg.sender), address(this), amountToDeposit);
        bool userDidntDeposit = user.firstRoundAmountToClaim == 0 && user.secondRoundAmountToClaim == 0;
        if (userDidntDeposit) {
            addressList.push(address(msg.sender));
        }
        user.secondRoundAmountToClaim = user.secondRoundAmountToClaim.add(offeringTokenReceived);
        offeringAmountSecondRoundTotal = offeringAmountSecondRoundTotal.add(offeringTokenReceived);
        emit Deposit(msg.sender, amountToDeposit, 2);
    }

    function depositThirdRound(uint256 _amountToPay) public onlyRegistered notZeroAmount(_amountToPay) onlyNotClaimed {
        require (block.number > secondRoundEndBlock, 'not the second round time');
        uint256 tokensLeftInPool = getTokensLeftInPool();
        require (tokensLeftInPool > 0, 'no tokens left in the pool');
        UserInfo storage user = userInfo[msg.sender];
        uint256 amountToDeposit = _amountToPay;
        uint256 offeringTokenReceived = _amountToPay.mul(offeringAmount).div(raisingAmount);

        if (tokensLeftInPool < offeringTokenReceived) {
            offeringTokenReceived = tokensLeftInPool;
            amountToDeposit = offeringTokenReceived.mul(raisingAmount).div(offeringAmount);
        }
        raisingToken.safeTransferFrom(address(msg.sender), address(this), amountToDeposit);
        bool userDidntDeposit = user.firstRoundAmountToClaim == 0
        && user.secondRoundAmountToClaim == 0
        && user.thirdRoundAmountToClaim == 0;
        if (userDidntDeposit) {
            addressList.push(address(msg.sender));
        }
        user.thirdRoundAmountToClaim = user.thirdRoundAmountToClaim.add(offeringTokenReceived);
        offeringAmountThirdRoundTotal = offeringAmountThirdRoundTotal.add(offeringTokenReceived);
        emit Deposit(msg.sender, amountToDeposit, 3);
    }

    function setOfferingAmount(uint256 _offerAmount) public onlyAdmin {
        require (block.number < firstRoundStartBlock, 'first round has been already started');
        offeringAmount = _offerAmount;
    }

    function setRaisingAmount(uint256 _raisingAmount) public onlyAdmin {
        require (block.number < firstRoundStartBlock, 'first round has been already started');
        raisingAmount= _raisingAmount;
    }

    function claim() public nonReentrant onlyNotClaimed {
        require (block.number > holdTokensTillBlock, 'claim has not been started');
        UserInfo storage user = userInfo[msg.sender];
        uint256 offeringTokenAmount = user.firstRoundAmountToClaim
        .add(user.secondRoundAmountToClaim)
        .add(user.thirdRoundAmountToClaim);
        require (offeringTokenAmount > 0, 'you didn`t participate');

        offeringToken.safeTransfer(address(msg.sender), offeringTokenAmount);
        user.claimed = true;
        emit Claim(msg.sender, offeringTokenAmount);
    }

    function isUserClaimed(address _user) external view returns(bool) {
        return userInfo[_user].claimed;
    }

    function getAddressListLength() external view returns(uint256) {
        return addressList.length;
    }

    function finalWithdraw(uint256 _lpAmount, uint256 _offerAmount) public onlyAdmin {
        require (_lpAmount < raisingToken.balanceOf(address(this)), 'not enough token 0');
        require (_offerAmount < offeringToken.balanceOf(address(this)), 'not enough token 1');
        raisingToken.safeTransfer(address(msg.sender), _lpAmount);
        offeringToken.safeTransfer(address(msg.sender), _offerAmount);
    }
}
