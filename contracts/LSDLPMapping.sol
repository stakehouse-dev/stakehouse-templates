// SPDX-License-Identifier: MIT


//Copyright (c) 2023 Blockswap Labs


//Permission is hereby granted, free of charge, to any person obtaining a copy
//of this software and associated documentation files (the "Software"), to deal
//in the Software without restriction, including without limitation the rights
//to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//copies of the Software, and to permit persons to whom the Software is
//furnished to do so, subject to the following conditions:


//The above copyright notice and this permission notice shall be included in all
//copies or substantial portions of the Software.


//THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT, OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.


pragma solidity 0.8.13;


interface ILiquidStakingManager {


    /// @notice Getter function for the savETHVault contract
    function savETHVault() external view returns (address);


    /// @notice Getter function for the stakingFundsVault contract  
    function stakingFundsVault() external view returns (address);


    /// @notice Getter function for the smartWalletOfKnot mapping which maps BLS Keys to the smart wallet addresses    
    function smartWalletOfKnot(bytes calldata _blsPublicKeyOfKnot) external view returns (address);


    /// @notice Getter function for the nodeRunnerOfSmartWallet mapping which maps smart wallet address to the node runner's address
    function nodeRunnerOfSmartWallet(address _smartWallet) external view returns (address);
}


interface ISavETHVault {


    /// @notice Getter function for lpTokenForKnot mapping that maps the BLS public keys to the minted dstETH tokens
    function lpTokenForKnot(bytes calldata _blsPublicKeyOfKnot) external view returns (address);
}


interface IStakingFundsVault {


    /// @notice Getter function for lpTokenForKnot mapping that maps the BLS public keys to the minted ETHLP tokens
    function lpTokenForKnot(bytes calldata _blsPublicKeyOfKnot) external view returns (address);
}


interface ILPToken {


    /// @notice Returns the current balance of LPTokens for a given depositor address
    function balanceOf(address _depositor) external view returns (uint256);
}


/// @notice Get an instance of the LiquidStakingManager contract for the provided address to get LPToken Balances and associated smart wallet.
/// @notice The LiquidStakingManager address can be queried from the LSD subgraph. For more info, please refer to https://docs.joinstakehouse.com/lsd/lsdSubgraph#lsdvalidator
contract LPBalances {


    /// @notice Stores the required LiquidStakingManager contract for the provided address
    ILiquidStakingManager public liquidStakingManager;
    /// @notice Stores the respective savETHVault contract for the provided LiquidStakingManager
    ISavETHVault public savETHVault;
    /// @notice Stores the respective stakingFundsVault contract for the provided LiquidStakingManager
    IStakingFundsVault public stakingFundsVault;


    /// @param _liquidStakingManager Address of the LiquidStakingManager deployed for a given BLS Key.
    constructor(address _liquidStakingManager) {
       
        liquidStakingManager = ILiquidStakingManager(_liquidStakingManager);
       
        // Get the savETHVault contract for the given LiquidStakingManager
        savETHVault = ISavETHVault(liquidStakingManager.savETHVault());


        // Get the stakingFundsVault contract for the given LiquidStakingManager
        stakingFundsVault = IStakingFundsVault(liquidStakingManager.stakingFundsVault());
    }


    /// @notice Returns the dstETH and ETHLP Token balances for the given BLS public key and depositor address
    /// @param _blsPublicKey The BLS Public Key registered for the LSD Validator
    /// @param _depositor The EOA address that deposited ETH in the staking pools.
    function getLPBalances(
        bytes memory _blsPublicKey,
        address _depositor
    ) external view returns (uint256, uint256) {


        // Get the dstETH Token minted by the savETHVault contract
        ILPToken dstETH = ILPToken(savETHVault.lpTokenForKnot(_blsPublicKey));
        // Get the ETHLP Token minted by te stakingFundsVault contract
        ILPToken ethLP = ILPToken(stakingFundsVault.lpTokenForKnot(_blsPublicKey));


        // Get the dstETH balance for the given depositor
        uint256 dstETHBalance = dstETH.balanceOf(_depositor);
        // Get the ETHLP balance for the given depositor
        uint256 ethLPBalance = ethLP.balanceOf(_depositor);


        return (dstETHBalance, ethLPBalance);
    }


    /// @notice Returns the SmartWallet address and the node runner's address for the given BLS Public Key
    /// @param _blsPublicKey The BLS Public Key registered for the LSD Validator
    function getNodeRunnerData(
        bytes memory _blsPublicKey
    ) external view returns (address, address) {
       
        // Get the smartWallet address associated with the given LiquidStakingManager
        address smartWallet = liquidStakingManager.smartWalletOfKnot(_blsPublicKey);
        // Get the node runner address associated with the smart wallet
        address nodeRunner = liquidStakingManager.nodeRunnerOfSmartWallet(smartWallet);
       
        return (smartWallet, nodeRunner);
    }
}
