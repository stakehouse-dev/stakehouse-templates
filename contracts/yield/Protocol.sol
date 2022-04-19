// SPDX MIT License

//Copyright (c) 2022 Blockswap Labs

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

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ISavETHManager } from "@blockswaplab/stakehouse-contracts/contracts/interfaces/ISavETHManager.sol";

interface IyvdETH {
    function mint(address _recipient, uint256 _amount) external;
    function burn(address _owner, uint256 _amount) external;
}

/// @notice Gives an idea of how dETH can be pooled together in order to earn yield within the Stakehouse protocol and then distribute it to your users
/// @notice Steps:
    // 1. Allow dETH deposits from users and mint shares 1:1 for x period of time
    // 2. Let DAO move dETH into savETH registry to earn yield in an index
    // 3. At some point DAO admin brings back dETH plus interest from the index by calling a single function
    // 4. Users can burn yvDETH to get their dETH + inflation
contract Protocol {

    /// @notice Address of DAO that governs this protocol
    address public admin;

    /// @notice Address of the share token
    ERC20 public yvdETH;

    /// @notice Contract Address of dETH token
    address public dETHAddress;

    /// @notice Contract address of savETH registry
    address public savETHRegistryAddress;

    /// @notice Index ID number owned by the contract
    uint256 public indexNumber;

    /// @notice count of tokens within the contract
    uint256 public dETHAmount;

    /// @notice Amount of tokens minted each time a KNOT is added to the universe.
    uint256 public KNOT_BATCH_AMOUNT = 24 ether;

    /// @notice Last block number when dETH can be deposited
    uint256 public lastDepositBlockNumber;

    /// @param _daoAddress Address of the DAO controlling the protocol dETH deposits and withdrawals
    /// @param _savETHRegistryAddress Address of the savETH registry managing indexes
    /// @param _dETHAddress Address of the dETH token that can be deposited in exchange for vaut tokens
    /// @param _lastDepositBlockNumber Last block number when a dETH token can be deposited by users
    constructor(
        address _daoAddress,
        address _savETHRegistryAddress,
        address _dETHAddress,
        uint256 _lastDepositBlockNumber
    ) {
        lastDepositBlockNumber = _lastDepositBlockNumber;

        admin = _daoAddress;

        // Set address of SavETHRegistry Smart Contract
        savETHRegistryAddress = _savETHRegistryAddress;

        // Set address of dETH token 
        dETHAddress = _dETHAddress;

        // unlimited approval for savETH registry
        ERC20(dETHAddress).approve(savETHRegistryAddress, (2 ** 256) - 1);

        // Deploy yvdETH token
        yvdETH = new ERC20("yvDETH", "yvDETH");

        // Storing the indexID
        indexNumber = ISavETHManager(_savETHRegistryAddress).createIndex(address(this));
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin!");
        _;
    }

    /// @notice Allows users to buy yvdETH shares by depositing their dETH
    /// @param _amount is amount of dETH tokens that the user wants to invest.
    function buyShares(uint256 _amount) public returns (uint256) {
        require(block.number <= lastDepositBlockNumber, "No more dETH deposits");

        // transfer dETH from user's ETH address to the contract
        ERC20(dETHAddress).transferFrom(msg.sender, address(this), _amount);
        dETHAmount += _amount;
        
        // mint yvdETH to user's ETH address 1:1 because this is first step in using protocol - no other dETH in contract
        IyvdETH(address(yvdETH)).mint(msg.sender, _amount);

        // return the amount of yvdETH minted to user's address
        return _amount;
    }

    /// @notice Allows users to burn yvdETH shares and redeem their dETH
    /// @param _amount is amount of dETH tokens that the user redeems after burning yvdETH.
    function burnShares(uint256 _amount) public returns (uint256) {
        require(block.number > lastDepositBlockNumber, "Not yet");
        require(dETHAmount > 0, "No dETH");

        uint256 redeemableAmount = ( _amount * dETHAmount ) / ERC20(address(yvdETH)).totalSupply();

        // burn yvdETH from user's ETH address
        IyvdETH(address(yvdETH)).burn(msg.sender, _amount);

        // transfer dETH from contract to user's ETH address
        ERC20(dETHAddress).transfer(msg.sender, redeemableAmount);
        dETHAmount -= redeemableAmount;

        // return the amount of dETH minted to user's address
        return redeemableAmount;
    }

    /// @notice Allows admin to move funds to savETH registry
    /// @param _stakeHouse Address of the Stakehouse
    /// @param _memberId Member ID of the KNOT
    function depositIntoSavETHRegistry(address _stakeHouse, bytes calldata _memberId) public onlyAdmin {
        require(block.number > lastDepositBlockNumber, "Not yet");
        ISavETHManager(savETHRegistryAddress).depositAndIsolateKnotIntoIndex(_stakeHouse, _memberId, indexNumber);

        // amount of dETH that was sent
        uint256 dETHRequiredForIsolation = KNOT_BATCH_AMOUNT + ISavETHManager(savETHRegistryAddress).dETHRewardsMintedForKnot(_memberId);
        dETHAmount -= dETHRequiredForIsolation;
    }

    /// @notice batch transaction to move funds to savETHRegistry
    /// @param _stakeHouse Array of addresses of the Stakehouse
    /// @param _memberId Array of member ID of the KNOTs
    function batchDepositIntoSavETHRegistry(address[] calldata _stakeHouse, bytes[] calldata _memberId) external onlyAdmin {
        require(_stakeHouse.length > 0, "Empty arrays");
        require(_stakeHouse.length == _memberId.length, "Unequal number of stakehouse and memberIDs");

        for(uint256 i; i < _stakeHouse.length; i++) {
            depositIntoSavETHRegistry(_stakeHouse[i], _memberId[i]);
        }
    }

    /// @notice Allows users to withdraw their KNOTs from SavETHRegistry
    /// @param _stakeHouse Address of the Stakehouse that the KNOT is part of
    /// @param _memberId Member ID of the KNOT in the Stakehouse
    function withdrawFromSavETHRegistry(address _stakeHouse, bytes calldata  _memberId) public onlyAdmin {
        require(block.number > lastDepositBlockNumber, "Not yet");

        // KNOT's indexID required to get dETHBalance
        uint256 indexIdForKnot = ISavETHManager(savETHRegistryAddress).associatedIndexIdForKnot(_memberId);

        // amount of dETH to be minted
        uint256 dETHBalance = ISavETHManager(savETHRegistryAddress).knotDETHBalanceInIndex(indexIdForKnot, _memberId);

        ISavETHManager(savETHRegistryAddress).addKnotToOpenIndexAndWithdraw(_stakeHouse, _memberId, address(this));

        dETHAmount += dETHBalance;
    }

    /// @notice Batch withdraw KNOTs from SavETHRegistry into the Open Pool
    /// @param _stakeHouse Array of Stakehouse Addresses
    /// @param _memberId Array of Member IDs which need to be withdrawn
    function batchWithdrawFromSavETHRegistry(address[] calldata _stakeHouse, bytes[] calldata _memberId) external onlyAdmin {
        require(_stakeHouse.length > 0, "Empty arrays");
        require(_stakeHouse.length == _memberId.length, "Unequal number of stakehouse and memberIDs");

        for(uint256 i; i < _stakeHouse.length; i++) {
            withdrawFromSavETHRegistry(_stakeHouse[i], _memberId[i]);
        }
    }

}
