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

import { Representative } from "./Representative.sol";
import { IDataStructures } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/IDataStructures.sol';

/// @notice Offer batch functions for representative work
contract BatchRepresentative is Representative {

    constructor(address _transactionRouter) Representative(_transactionRouter) {}

    /// @notice Facilitate batch registration of validators
    function batchRegisterValidatorInitials(
        address _representee,
        bytes[] calldata _blsPublicKey,
        bytes[] calldata _blsSignature
    ) external {
        require(_blsPublicKey.length == _blsPublicKey.length, 'Length mismatch');

        for (uint256 i; i < _blsPublicKey.length; ++i) {
            registerValidatorInitials(
                _representee,
                _blsPublicKey[i],
                _blsSignature[i]
            );
        }
    }

    /// @notice Facilitate multiple deposits for multiple pub keys
    function batchRegisterDeposit(
        address _representee,
        bytes[] calldata _blsPublicKey,
        bytes[] calldata _ciphertext,
        bytes[] calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature[] calldata _encryptionSignature,
        bytes32[] calldata _dataRoot
    ) external payable {
        require(_blsPublicKey.length == _ciphertext.length, 'Length mismatch');
        require(_ciphertext.length == _aesEncryptorKey.length, 'Length mismatch');
        require(_aesEncryptorKey.length == _encryptionSignature.length, 'Length mismatch');
        require(_encryptionSignature.length == _dataRoot.length, 'Length mismatch');

        for (uint256 i; i < _blsPublicKey.length; ++i) {
            registerDeposit(
                _representee,
                _blsPublicKey[i],
                _ciphertext[i],
                _aesEncryptorKey[i],
                _encryptionSignature[i],
                _dataRoot[i]
            );
        }
    }

    /// @notice Allow multiple knots to join the same house, brand and index
    function batchJoinStakehouses(
        address _representee,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        bytes[] calldata _blsPublicKey,
        IDataStructures.ETH2DataReport[] calldata _eth2Report,
        IDataStructures.EIP712Signature[] calldata _reportSignature
    ) external {
        require(_blsPublicKey.length == _eth2Report.length, 'Length mismatch');
        require(_eth2Report.length == _reportSignature.length, 'Length mismatch');

        for (uint256 i; i < _blsPublicKey.length; ++i) {
            joinStakehouse(
                _representee,
                _blsPublicKey[i],
                _stakehouse,
                _brandTokenId,
                _savETHIndexId,
                _eth2Report[i],
                _reportSignature[i]
            );
        }
    }
}
