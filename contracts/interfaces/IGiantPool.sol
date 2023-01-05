pragma solidity ^0.8.4;
//import "./IGiantMevAndFeesPool.sol";
//import "./IGiantSavETHVaultPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IGiantPool {
    function lpTokenETH() external view returns(address);
    /// @dev Deposit ETH into the a pool
    ///
    /// @param _amount The amount of ETH to deposit.
    function depositETH(uint256 _amount) external payable;

    /// @dev Withdraw ETH from the a pool
    ///
    /// @param _amount of LP tokens to exchange for some amount of ETH
    function withdrawETH(uint256 _amount) external;

    /// @dev Withdraw vault LP tokens by burning their giant LP tokens
    ///
    /// @param _lpTokens List of LP tokens to be withdrawn from the giant pool
    /// @param _amounts List of amounts of giant LP being burnt in exchange for vault LP
    function withdrawLPTokens(ERC20[] calldata _lpTokens, uint256[] calldata _amounts) external;
}
