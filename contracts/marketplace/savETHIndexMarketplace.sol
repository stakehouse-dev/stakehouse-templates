// SPDX-License-Identifier: MIT

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

import { ISavETHManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISavETHManager.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @notice Hello tradable index rates and rights!
/// @notice List your entire index of KNOTs on the open market by approving such a marketplace contract
contract savETHIndexMarketplace is ReentrancyGuard {

    event IndexListed(uint256 indexed indexId);
    event KnotInIndexListed(uint256 indexed indexId, bytes blsPubKey);
    event IndexSold(uint256 indexed indexId);
    event KnotInIndexSold(uint256 indexed indexId, bytes blsPubKey);

    /// @notice Listing metadata - who is selling the index and for how much
    struct Listing {
        uint256 priceInETH;
        address seller;
        bool sold;
    }

    /// @notice Assume that an index being listed has at least 1 KNOT
    uint256 public constant MINIMUM_LISTING_PRICE = 24 ether;

    /// @notice Index specific listing metadata
    mapping(uint256 => Listing) public indexListing;

    /// @notice Listing for a single knot isolated in a savETH index
    mapping(bytes => Listing) public singleKnotInIndexListing;

    /// @notice Address of the savETH registry manager
    ISavETHManager public savETHRegistry;

    constructor(ISavETHManager _savETHRegistry) {
        savETHRegistry = _savETHRegistry;
    }

    /// @notice Allow an index owner that has approved this contract to list their index of KNOT for sale accepting ETH as the currency
    /// @param _indexId ID of the index being listed
    /// @param _priceInETH Amount in wei the index will be listed
    function listIndexForETH(uint256 _indexId, uint256 _priceInETH) external {
        require(_priceInETH >= MINIMUM_LISTING_PRICE, "Price below minimum");

        address seller = savETHRegistry.indexIdToOwner(_indexId);
        require(seller == msg.sender, "Only owner");

        indexListing[_indexId] = Listing({
            priceInETH: _priceInETH,
            seller: seller,
            sold: false
        });

        emit IndexListed(_indexId);
    }

    /// @notice Allow an index owner that has approved this contract to list one KNOT in their index for sale accepting ETH as the currency
    /// @param _blsPubKey Validator ID
    /// @param _priceInETH Amount in wei the knot will be listed
    function listKnotInIndexForETH(bytes calldata _blsPubKey, uint256 _priceInETH) external {
        require(_priceInETH >= MINIMUM_LISTING_PRICE, "Price below minimum");

        uint256 associatedIndexIdForKnot = savETHRegistry.associatedIndexIdForKnot(_blsPubKey);
        address seller = savETHRegistry.indexIdToOwner(associatedIndexIdForKnot);
        require(seller == msg.sender, "Only owner");

        singleKnotInIndexListing[_blsPubKey] = Listing({
            priceInETH: _priceInETH,
            seller: seller,
            sold: false
        });

        emit KnotInIndexListed(associatedIndexIdForKnot, _blsPubKey);
    }

    /// @notice Purchase an index listed for sale
    /// @param _indexId ID of the index
    /// @param _recipient Address that will receive the index ownership which could be a different address to one paying
    function buyIndex(uint256 _indexId, address _recipient) external payable nonReentrant {
        require(indexListing[_indexId].seller != address(0), "No listing exists");
        require(!indexListing[_indexId].sold, "Sold");
        require(msg.value == indexListing[_indexId].priceInETH, "Not enough ETH");
        require(_recipient != address(0), "Recipient is zero");
        require(_recipient != address(this), "Recipient is this contract");

        // here the marketplace could take a % commission
        (bool success, ) = indexListing[_indexId].seller.call{value: msg.value}("");
        require(success, "Failed to transfer ETH");

        indexListing[_indexId].sold = true;

        savETHRegistry.transferIndexOwnership(_indexId, _recipient);

        emit IndexSold(_indexId);
    }

    function buyKnotInIndex(address _associatedStakehouseForKnot, bytes calldata _blsPubKey, uint256 _targetIndexId) external payable nonReentrant {
        require(singleKnotInIndexListing[_blsPubKey].seller != address(0), "No listing exists");
        require(!singleKnotInIndexListing[_blsPubKey].sold, "Sold");
        require(msg.value == singleKnotInIndexListing[_blsPubKey].priceInETH, "Not enough ETH");

        // here the marketplace could take a % commission
        (bool success, ) = singleKnotInIndexListing[_blsPubKey].seller.call{ value: msg.value }("");
        require(success, "Failed to transfer ETH");

        singleKnotInIndexListing[_blsPubKey].sold = true;

        uint256 currentKnotIndexId = savETHRegistry.associatedIndexIdForKnot(_blsPubKey);

        savETHRegistry.transferKnotToAnotherIndex(_associatedStakehouseForKnot, _blsPubKey, _targetIndexId);

        emit KnotInIndexSold(currentKnotIndexId, _blsPubKey);
    }

    // There is plenty of additional logic that can be added including
    // - Ability to cancel a listing
    // - Commission for marketplace
}
