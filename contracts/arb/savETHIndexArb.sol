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

import { ISavETHManager } from "@blockswaplab/stakehouse-contracts/contracts/interfaces/ISavETHManager.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contracts/contracts/interfaces/ITransactionRouter.sol";
import { IDataStructures } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/IDataStructures.sol';

interface ITransactionRouterExtended {
    function balanceIncrease(
        address _stakeHouse,
        bytes calldata _memberId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;
}

contract savETHIndexArb {

    uint256 public immutable indexIdOwnedByContract;
    ISavETHManager public savETHRegistry;
    ITransactionRouterExtended public router;

    struct KNOT {
        address stakeHouse;
        bytes blsPubKey;
    }

    constructor(ISavETHManager _savETHRegistry, ITransactionRouterExtended _router) {
        savETHRegistry = _savETHRegistry;
        router = _router;
        indexIdOwnedByContract = savETHRegistry.createIndex(address(this)); // Index owned by the contract will own knots for arb
    }

    function arb(
        KNOT calldata _oldKnotShares,
        KNOT calldata _newKnotShares,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external {
        savETHRegistry.addKnotToOpenIndex(_oldKnotShares.stakeHouse, _oldKnotShares.blsPubKey);
        savETHRegistry.isolateKnotFromOpenIndex(_newKnotShares.stakeHouse, _newKnotShares.blsPubKey, indexIdOwnedByContract);

        router.balanceIncrease(_newKnotShares.stakeHouse, _newKnotShares.blsPubKey, _eth2Report, _reportSignature);

        savETHRegistry.addKnotToOpenIndex(_newKnotShares.stakeHouse, _newKnotShares.blsPubKey);
        savETHRegistry.isolateKnotFromOpenIndex(_oldKnotShares.stakeHouse, _oldKnotShares.blsPubKey, indexIdOwnedByContract);
    } // walk away with savETH profits from reporting balance increase
}