// SPDX-License-Identifier: GPL-3.0

pragma solidity =0.6.12;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "./WakaToken.sol";

contract WakaFarm is Ownable {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDebt; // Reward debt. See explanation below.
        //
        // We do some fancy math here. Basically, any point in time, the amount of Waka
        // entitled to a user but is pending to be distributed is:
        //
        //   pending reward = (userInfo.amount * pool.accWakaPerShare) - userInfo.rewardDebt
        //
        // Whenever a user deposits or withdraws LP tokens to a pool. Here's what happens:
        //   1. The pool's `accWakaPerShare` (and `lastRewardBlock`) gets updated.
        //   2. User receives the pending reward sent to his/her address.
        //   3. User's `amount` gets updated.
        //   4. User's `rewardDebt` gets updated.
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 token; // Address of token or LP contract
        uint256 allocPoint; // How many allocation points assigned to this pool. Waka to distribute per block.
        uint256 lastRewardBlock; // Last block number that Waka distribution occurs.
        uint256 accWakaPerShare; // Accumulated Waka per share, times 1e12. See below.
    }

    // Waka tokens created first block. -> x Waka per block to start
    uint256 public wakaStartBlock;
    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when Waka mining starts ->
    uint256 public startBlock;
    // Block number when bonus Waka period ends.
    uint256 public bonusEndBlock;
    // how many block size will change the common difference before bonus end.
    uint256 public bonusBeforeBulkBlockSize;
    // how many block size will change the common difference after bonus end.
    uint256 public bonusEndBulkBlockSize;
    // Waka tokens created at bonus end block. ->
    uint256 public wakaBonusEndBlock;
    // max reward block
    uint256 public maxRewardBlockNumber;
    // bonus before the common difference
    uint256 public bonusBeforeCommonDifference;
    // bonus after the common difference
    uint256 public bonusEndCommonDifference;
    // Accumulated Waka per share, times 1e12.
    uint256 public accWakaPerShareMultiple = 1E12;
    // The WakaSwap token!
    WakaToken public waka;
    // Dev address.
    address public devAddr;
    // Info on each pool added
    PoolInfo[] public poolInfo;
    // Info of each user that stakes tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        WakaToken _waka,
        address _devAddr,
        uint256 _wakaStartBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock,
        uint256 _bonusBeforeBulkBlockSize,
        uint256 _bonusBeforeCommonDifference,
        uint256 _bonusEndCommonDifference
    ) public {
        waka = _waka;
        devAddr = _devAddr;
        wakaStartBlock = _wakaStartBlock;
        startBlock = _startBlock;
        bonusEndBlock = _bonusEndBlock;
        bonusBeforeBulkBlockSize = _bonusBeforeBulkBlockSize;
        bonusBeforeCommonDifference = _bonusBeforeCommonDifference;
        bonusEndCommonDifference = _bonusEndCommonDifference;
        bonusEndBulkBlockSize = bonusEndBlock.sub(startBlock);
        // waka created when bonus end first block
        // (wakaStartBlock - bonusBeforeCommonDifference * ((bonusEndBlock-startBlock)/bonusBeforeBulkBlockSize - 1)) * bonusBeforeBulkBlockSize*(bonusEndBulkBlockSize/bonusBeforeBulkBlockSize) * bonusEndBulkBlockSize
        wakaBonusEndBlock = wakaStartBlock
        .sub(bonusEndBlock.sub(startBlock).div(bonusBeforeBulkBlockSize).sub(1).mul(bonusBeforeCommonDifference))
        .mul(bonusBeforeBulkBlockSize)
        .mul(bonusEndBulkBlockSize.div(bonusBeforeBulkBlockSize))
        .div(bonusEndBulkBlockSize);
        // max mint block number, _wakaInitBlock - (MAX-1)*_commonDifference = 0
        // MAX = startBlock + bonusEndBulkBlockSize * (_wakaInitBlock/_commonDifference + 1)
        maxRewardBlockNumber = startBlock.add(
            bonusEndBulkBlockSize.mul(wakaBonusEndBlock.div(bonusEndCommonDifference).add(1))
        );
    }

    // Pool Length
    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    // Add a new token or LP to the pool. Can only be called by the owner.
    // XXX DO NOT add the same LP token more than once. Rewards will be messed up if you do!
    function add(
        uint256 _allocPoint,
        IERC20 _token,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
          token: _token,
          allocPoint: _allocPoint,
          lastRewardBlock: lastRewardBlock,
          accWakaPerShare: 0
        }));
    }

    // Update the given pool's Waka allocation point. Can only be called by the owner.
    function set(
        uint256 _pid,
        uint256 _allocPoint,
        bool _withUpdate
    ) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }

    // (_from,_to]
    function getTotalRewardInfoInSameCommonDifference(
        uint256 _from,
        uint256 _to,
        uint256 _wakaInitBlock,
        uint256 _bulkBlockSize,
        uint256 _commonDifference
    ) public view returns (uint256 totalReward) {
        if (_to <= startBlock || maxRewardBlockNumber <= _from) {
            return 0;
        }
        if (_from < startBlock) {
            _from = startBlock;
        }
        if (maxRewardBlockNumber < _to) {
            _to = maxRewardBlockNumber;
        }
        uint256 currentBulkNumber = _to.sub(startBlock).div(_bulkBlockSize).add(
            _to.sub(startBlock).mod(_bulkBlockSize) > 0 ? 1 : 0
        );
        if (currentBulkNumber < 1) {
            currentBulkNumber = 1;
        }
        uint256 fromBulkNumber = _from.sub(startBlock).div(_bulkBlockSize).add(
            _from.sub(startBlock).mod(_bulkBlockSize) > 0 ? 1 : 0
        );
        if (fromBulkNumber < 1) {
            fromBulkNumber = 1;
        }
        if (fromBulkNumber == currentBulkNumber) {
            return _to.sub(_from).mul(_wakaInitBlock.sub(currentBulkNumber.sub(1).mul(_commonDifference)));
        }
        uint256 lastRewardBulkLastBlock = startBlock.add(_bulkBlockSize.mul(fromBulkNumber));
        uint256 currentPreviousBulkLastBlock = startBlock.add(_bulkBlockSize.mul(currentBulkNumber.sub(1)));
        {
            uint256 tempFrom = _from;
            uint256 tempTo = _to;
            totalReward = tempTo
            .sub(tempFrom > currentPreviousBulkLastBlock ? tempFrom : currentPreviousBulkLastBlock)
            .mul(_wakaInitBlock.sub(currentBulkNumber.sub(1).mul(_commonDifference)));
            if (lastRewardBulkLastBlock > tempFrom && lastRewardBulkLastBlock <= tempTo) {
                totalReward = totalReward.add(
                    lastRewardBulkLastBlock.sub(tempFrom).mul(
                        _wakaInitBlock.sub(fromBulkNumber > 0 ? fromBulkNumber.sub(1).mul(_commonDifference) : 0)
                    )
                );
            }
        }
        {
            // avoids stack too deep errors
            uint256 tempWakaInitBlock = _wakaInitBlock;
            uint256 tempBulkBlockSize = _bulkBlockSize;
            uint256 tempCommonDifference = _commonDifference;
            if (currentPreviousBulkLastBlock > lastRewardBulkLastBlock) {
                uint256 tempCurrentPreviousBulkLastBlock = currentPreviousBulkLastBlock;
                // sum( [fromBulkNumber+1, currentBulkNumber] )
                // 1/2 * N *( a1 + aN)
                uint256 N = tempCurrentPreviousBulkLastBlock.sub(lastRewardBulkLastBlock).div(tempBulkBlockSize);
                if (N > 1) {
                    uint256 a1 = tempBulkBlockSize.mul(
                        tempWakaInitBlock.sub(
                            lastRewardBulkLastBlock.sub(startBlock).mul(tempCommonDifference).div(tempBulkBlockSize)
                        )
                    );
                    uint256 aN = tempBulkBlockSize.mul(
                        tempWakaInitBlock.sub(
                            tempCurrentPreviousBulkLastBlock.sub(startBlock).div(tempBulkBlockSize).sub(1).mul(
                                tempCommonDifference
                            )
                        )
                    );
                    totalReward = totalReward.add(N.mul(a1.add(aN)).div(2));
                } else {
                    totalReward = totalReward.add(
                        tempBulkBlockSize.mul(tempWakaInitBlock.sub(currentBulkNumber.sub(2).mul(tempCommonDifference)))
                    );
                }
            }
        }
    }

    // Return total reward over the given _from to _to block.
    function getTotalRewardInfo(uint256 _from, uint256 _to) public view returns (uint256 totalReward) {
        if (_to <= bonusEndBlock) {
            totalReward = getTotalRewardInfoInSameCommonDifference(
                _from,
                _to,
                wakaStartBlock,
                bonusBeforeBulkBlockSize,
                bonusBeforeCommonDifference
            );
        } else if (_from >= bonusEndBlock) {
            totalReward = getTotalRewardInfoInSameCommonDifference(
                _from,
                _to,
                wakaBonusEndBlock,
                bonusEndBulkBlockSize,
                bonusEndCommonDifference
            );
        } else {
            totalReward = getTotalRewardInfoInSameCommonDifference(
                _from,
                bonusEndBlock,
                wakaStartBlock,
                bonusBeforeBulkBlockSize,
                bonusBeforeCommonDifference
            )
            .add(
                getTotalRewardInfoInSameCommonDifference(
                    bonusEndBlock,
                    _to,
                    wakaBonusEndBlock,
                    bonusEndBulkBlockSize,
                    bonusEndCommonDifference
                )
            );
        }
    }

    // View function to see pending Waka on frontend.
    function pendingWaka(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accWakaPerShare = pool.accWakaPerShare;
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0 && pool.lastRewardBlock < maxRewardBlockNumber) {
            uint256 totalReward = getTotalRewardInfo(pool.lastRewardBlock, block.number);
            uint256 wakaReward = totalReward.mul(pool.allocPoint).div(totalAllocPoint);
            accWakaPerShare = accWakaPerShare.add(wakaReward.mul(accWakaPerShareMultiple).div(lpSupply));
        }
        return user.amount.mul(accWakaPerShare).div(accWakaPerShareMultiple).sub(user.rewardDebt);
    }

    // Update reward vairables for all pools. Be careful of gas spending!
    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    // Update reward variables of the given pool to be up-to-date.
    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.token.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        if (pool.lastRewardBlock >= maxRewardBlockNumber) {
            return;
        }
        uint256 totalReward = getTotalRewardInfo(pool.lastRewardBlock, block.number);
        uint256 wakaReward = totalReward.mul(pool.allocPoint).div(totalAllocPoint);
        waka.mintTo(devAddr, wakaReward.div(20)); // 5% Waka sent to dev addr every harvest
        waka.mintTo(address(this), wakaReward);
        pool.accWakaPerShare = pool.accWakaPerShare.add(wakaReward.mul(accWakaPerShareMultiple).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

    // Deposit tokens to WakaFarm for Waka allocation.
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accWakaPerShare).div(accWakaPerShareMultiple).sub(
                user.rewardDebt
            );
            if (pending > 0) {
                safeWakaTransfer(msg.sender, pending);
            }
        }
        pool.token.safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(pool.accWakaPerShare).div(accWakaPerShareMultiple);
        emit Deposit(msg.sender, _pid, _amount);
    }

    // Withdraw tokens from WakaFarm
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, 'withdraw: not good');
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accWakaPerShare).div(accWakaPerShareMultiple).sub(
            user.rewardDebt
        );
        if (pending > 0) {
            safeWakaTransfer(msg.sender, pending);
        }
        if (_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.token.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accWakaPerShare).div(accWakaPerShareMultiple);
        emit Withdraw(msg.sender, _pid, _amount);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.token.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

    // Safe waka transfer function, just in case if rounding error causes pool to not have enough $Waka
    function safeWakaTransfer(address _to, uint256 _amount) internal {
        uint256 wakaBal = waka.balanceOf(address(this));
        if (_amount > wakaBal) {
            waka.transfer(_to, wakaBal);
        } else {
            waka.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev or governance
    function changeDevAddr(address _devAddr) public {
        require(msg.sender == devAddr, 'bruh');
        devAddr = _devAddr;
    }
}
