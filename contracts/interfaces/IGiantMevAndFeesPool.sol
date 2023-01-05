pragma solidity ^0.8.4;
import "./IGiantPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IGiantMevAndFeesPool is IGiantPool {
    /// @notice Allow a giant LP to claim a % of the revenue received by the MEV and Fees Pool
    function claimRewards(
        address _recipient,
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) external;
}
