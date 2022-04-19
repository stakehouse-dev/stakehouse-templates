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

import { ISavETHManager } from "@blockswaplab/stakehouse-contracts/contracts/interfaces/ISavETHManager.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Given the contract owns one or more indices of KNOTs, fractionalize the value by issuing tokens
/// @dev Maybe even take a commission on top of the dETH rewards your index will earn!
contract savETHIndexERC20Fund is ERC20("Shares", "shr") {

    /// @notice If the contract creates and owns an index, the ID of the index
    /// @dev Ownership of any index can be transferred to this contract. This is just to show how a contract-created index could be tracked
    uint256 public indexId;

    /// @notice On deploy, spin up an empty index owned by the contract and fractionalize it by issuing shares. dETH from various knots can then be added into the index by anyone
    /// @param _savETHRegistry Address of the registry that tracks all indices for dETH holders
    /// @param _shareRecipient Recipient that will receive 100% of the shares issued by the smart contract after the index is created
    constructor(address _savETHRegistry, address _shareRecipient) {
        // Create an index on construction owned by this contract. Coordination of adding knots into this index will be done outside the contract
        indexId = ISavETHManager(_savETHRegistry).createIndex(address(this));

        // Mint a fixed supply of shares of the savETH index or indices owned by the smart contact
        // The recipient will distribute this to various buyers...
        // Each token then represents a fraction of the underlying savETH index.
        _mint(_shareRecipient, 5_000_000 ether);
    }

    // Add your own logic. For example:
    // - Issue dETH dividend to all token holders.
    // - etc.
}