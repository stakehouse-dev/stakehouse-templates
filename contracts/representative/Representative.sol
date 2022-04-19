pragma solidity 0.8.13;

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

import { IRepresentative } from '../interfaces/IRepresentative.sol';
import { IDataStructures } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/IDataStructures.sol';
import { ITransactionRouter } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/ITransactionRouter.sol';
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

/// @notice Template for contract to manage representees
contract Representative is IRepresentative, Ownable {

    /// @notice Transaction Router address
    ITransactionRouter public immutable TRANSACTION_ROUTER;

    /// @notice Amount to deposit in order to activate the validator
    uint256 public constant DEPOSIT_AMOUNT = 32 ether;

    constructor(address _transactionRouter) {
        TRANSACTION_ROUTER = ITransactionRouter(_transactionRouter);
    }

    /// @inheritdoc IRepresentative
    function isRepresentativeApproved(address _representee) external override view returns (bool) {
        return TRANSACTION_ROUTER.userToRepresentativeStatus(_representee, address(this));
    }

    /// @inheritdoc IRepresentative
    function registerValidatorInitials(
        address _representee, bytes calldata _blsPublicKey, bytes calldata _blsSignature
    ) public override onlyOwner {
        TRANSACTION_ROUTER.registerValidatorInitials(
            _representee, _blsPublicKey, _blsSignature
        );
    }

    /// @inheritdoc IRepresentative
    function registerDeposit(
        address _representee,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) override public payable onlyOwner {
        TRANSACTION_ROUTER.registerValidator{value: DEPOSIT_AMOUNT}(
            _representee,
            _blsPublicKey,
            _ciphertext,
            _aesEncryptorKey,
            _encryptionSignature,
            _dataRoot
        );
    }

    /// @inheritdoc IRepresentative
    function createStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) public override onlyOwner {
        TRANSACTION_ROUTER.createStakehouse(
            _representee,
            _blsPublicKey,
            _ticker,
            _savETHIndexId,
            _eth2Report,
            _reportSignature
        );
    }

    /// @inheritdoc IRepresentative
    function joinStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) public override onlyOwner {
        TRANSACTION_ROUTER.joinStakehouse(
            _representee,
            _blsPublicKey,
            _stakehouse,
            _brandTokenId,
            _savETHIndexId,
            _eth2Report,
            _reportSignature
        );
    }
}
