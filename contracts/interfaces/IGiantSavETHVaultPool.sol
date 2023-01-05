pragma solidity ^0.8.4;
import "./IGiantPool.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IGiantSavETHVaultPool is IGiantPool {
    /// @notice Allow a user to burn their giant LP in exchange for dETH that is ready to withdraw from a set of savETH vaults
    /// @param _savETHVaults List of savETH vaults being interacted with
    /// @param _lpTokens List of savETH vault LP being burnt from the giant pool in exchange for dETH
    /// @param _amounts Amounts of giant LP the user owns which is burnt 1:1 with savETH vault LP and in turn that will give a share of dETH
    function withdrawDETH(
        address[] calldata _savETHVaults,
        address[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external;
}
