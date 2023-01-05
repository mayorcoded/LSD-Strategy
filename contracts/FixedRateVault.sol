//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;
import "hardhat/console.sol";
import "./helpers/errors.sol";
import "./interfaces/IGiantMevAndFeesPool.sol";
import "./interfaces/IGiantSavETHVaultPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ANNUAL_FIXED_RATE } from "./helpers/constants.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract FixedRateVault is AccessControl, ERC20, ReentrancyGuard {

    struct UserStake {
        // The amount staked by the user
        uint256 stakeAmount;
        // The time the user staked the amount
        uint256 stakeTime;
        // User staking status
        bool hasStake;
    }

    /// @dev dETH
    IERC20 public immutable dETH;

    /// @dev GiantSavETHPool
    IGiantSavETHVaultPool public immutable giantSavETHPool;

    /// @dev GiantFeesAndMevPool
    IGiantMevAndFeesPool public immutable giantMevAndFeesPool;

    mapping(address => UserStake) userStakes;

    /// @dev The identifier of the role which maintains other roles.
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN");

    /// @dev Identifier for the Configurator (owner) role
    bytes32 public constant VAULT_MANAGER_ROLE = keccak256("VAULT_MANAGER_ROLE");

    /// @dev A modifier which checks if caller is an admin
    modifier onlyAdmin() {
        if (!hasRole(ADMIN_ROLE, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }
    /// @dev A modifier which checks if caller is an admin or has the pause role.
    modifier onlyVaultManager() {
        if (!hasRole(VAULT_MANAGER_ROLE, msg.sender)) {
            revert Unauthorized();
        }
        _;
    }

    /// @notice Emitted when a user claims ETH from the vault
    ///
    /// @param amount The amount of ETH reward claimed
    event ClaimRewards(uint amount);

    /// @notice Emitted when a vault manager claims ETH from MevFees pool
    ///
    /// @param amount The amount of ETH reward claimed
    event ClaimETHRewards(uint amount);

    /// @notice Emitted when a user deposits into the vault
    ///
    /// @param depositor The depositor of the funds
    /// @param amount The amount of ETH deposited
    event Deposit(address depositor, uint256 amount);

    /// @notice Emitted when an account is created.
    ///
    /// @param giantSavETHPool The address of the giantSavETHPool.
    /// @param giantSavETHPoolAmount The amount deposited into the giantSavETHPool.
    /// @param giantMevAndFeesPool The address of the giantMevAndFeesPool.
    /// @param giantMevAndFeesPoolAmount The amount deposited into the giantMevAndFeesPool.
    event DepositETH(
        address giantSavETHPool,
        uint256 giantSavETHPoolAmount,
        address giantMevAndFeesPool,
        uint256 giantMevAndFeesPoolAmount
    );

    /// @notice Emitted when ETH is withdrawn from either giant pools
    ///
    /// @param pool The address of the giant pool.
    /// @param amount The amount of eth withdrawn.
    event WithdrawETH(address pool, uint256 amount);

    /// @notice Emitted when DETH is withdrawn from the giantSavETHPool.
    ///
    /// @param dETHAmount The amount of dETH withdrawn
    event WithdrawDETH(uint256 dETHAmount);

    constructor(
        address _dETH,
        address _savETHPool,
        address _mevAndFeesPool
    ) ERC20("GPT-LP", "Giant Pool Token") {
        dETH = IERC20(_dETH);
        giantSavETHPool = IGiantSavETHVaultPool(_savETHPool);
        giantMevAndFeesPool = IGiantMevAndFeesPool(_mevAndFeesPool);

        _setupRole(ADMIN_ROLE, msg.sender);
        _setupRole(VAULT_MANAGER_ROLE, msg.sender);
        _setRoleAdmin(ADMIN_ROLE, ADMIN_ROLE);
        _setRoleAdmin(VAULT_MANAGER_ROLE, ADMIN_ROLE);
    }

    function deposit(uint256 _amount) external nonReentrant payable {
        require(_amount > 0, "Amount should be greater than 0");
        require(msg.value == _amount, "Amount sent must be equal to amount passed");

        UserStake storage userStake = userStakes[msg.sender];
        userStake.stakeAmount +=_amount;
        userStake.stakeTime = block.timestamp;
        userStake.hasStake = true;

        _mint(msg.sender, _amount);
        _depositETH(_amount);
        emit Deposit(msg.sender, _amount);
    }

    function depositETH(uint256 amount) onlyVaultManager external {
        _depositETH(amount);
    }

    function _depositETH(uint256 _amount)
        internal
    {
        require(_amount > 0, "Amount should be greater than 0");
        require(msg.value == _amount, "Amount sent must be equal to amount passed");

        //split deposit into 2 parts: 90% into zero-risk pool, 10% high-risk pool
        uint256 giantSavETHPoolAmount = (90 * _amount) / 100;
        uint256 giantMevAndFeesPoolAmount = _amount - giantSavETHPoolAmount;

        giantSavETHPool.depositETH{ value: giantSavETHPoolAmount }(giantSavETHPoolAmount);
        giantMevAndFeesPool.depositETH{ value: giantMevAndFeesPoolAmount }(giantMevAndFeesPoolAmount);

        emit DepositETH(
            address (giantSavETHPool),
            giantSavETHPoolAmount,
            address (giantMevAndFeesPool),
            giantMevAndFeesPoolAmount
        );
    }


    function withdrawETH(address pool, uint256 amount) onlyVaultManager external {
        if(pool == address(giantSavETHPool)) {
            giantSavETHPool.withdrawETH(amount);
        } else if(pool == address(giantMevAndFeesPool)) {
            giantMevAndFeesPool.withdrawETH(amount);
        } else {
            return;
        }

        emit WithdrawETH(pool, amount);
    }


    function withdrawDETH(
        address[] calldata _savETHVaults,
        address[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external onlyVaultManager payable {
        uint256 initialBalances = dETH.balanceOf(address(this));
        giantSavETHPool.withdrawDETH(
            _savETHVaults,
            _lpTokens,
            _amounts
        );

        uint256 amount = dETH.balanceOf(address(this)) - initialBalances;
        emit WithdrawDETH(amount);
    }

    function claimETHRewards(
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) onlyVaultManager payable external {
        uint256 initialBalances = address(this).balance;
        giantMevAndFeesPool.claimRewards(
            address(this),
            _stakingFundsVaults,
            _blsPublicKeysForKnots
        );

        uint256 amount = address(this).balance - initialBalances;
        emit ClaimETHRewards(amount);
    }

    function claimRewards() external {
        UserStake storage userStake = userStakes[msg.sender];
        require(userStake.hasStake, "inactive stake");

        uint256 userReward = (userStake.stakeAmount
            * (ANNUAL_FIXED_RATE) *
            ((block.timestamp - userStake.stakeTime) / 365 days)) / 1e18;
        userStake.stakeTime = block.timestamp;
        payable(msg.sender).transfer(userReward);
        emit ClaimRewards(userReward);
    }


    function withdraw(uint256 amount) external {
        UserStake storage userStake = userStakes[msg.sender];
        require(userStake.hasStake, "inactive stake");
        require(amount <= userStake.stakeAmount, "insufficient funds");

        if(userStake.stakeAmount == amount){
            userStake.hasStake = false;
        }

        _burn(msg.sender, amount);
        userStake.stakeAmount -= amount;
        uint256 balance = address(this).balance;
        if (balance > amount) {
            payable(msg.sender).transfer(amount);
            return;
        }
        _withdrawETHFromPools(amount);
        payable(msg.sender).transfer(amount);
    }

    function _withdrawETHFromPools(uint256 amount) internal {
        // withdraw from giant savETHPool
        uint256 savETHPoolStakingBalance = IERC20(
            giantSavETHPool.lpTokenETH()
        ).balanceOf(address(this));
        if (savETHPoolStakingBalance >= amount) {
            giantSavETHPool.withdrawETH(amount);
            return;
        }

        giantSavETHPool.withdrawETH(savETHPoolStakingBalance);
        amount -= savETHPoolStakingBalance;
        // try remainder from
        uint256 mevAndFeesPoolStakingBalance = IERC20(giantMevAndFeesPool.lpTokenETH())
        .balanceOf(address(this));
        if (mevAndFeesPoolStakingBalance >= amount) {
            giantMevAndFeesPool.withdrawETH(amount);
            return;
        }
        revert("Insufficient funds");
    }
}
