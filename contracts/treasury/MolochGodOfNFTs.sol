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

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IDataStructures } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/IDataStructures.sol';
import { ITransactionRouter } from '@blockswaplab/stakehouse-contracts/contracts/interfaces/ITransactionRouter.sol';

/// @notice Allow a collective to sacrifice ETH to Moloch up to the 32 ETH staking requirement in order to set up 1 validator.
/// @notice In exchange get an NFT reflecting your contribution which will be your pro-rata share of derivatives.
contract MolochGodOfNFTs is ERC721("MolochGodOfNFTs", "mNFT") {

    event ProposalSubmitted(uint256 proposalId);
    event ProposalExecuted(uint256 proposalId);

    struct TxProposal {
        bool executed; // Whether the tx has been executed or not
        address to; // Target address or zero address for a contract deployment
        bytes data; // Call data that will be attached to the TX
        uint256 value; // Value that will be attached to the TX
        uint256 proposer; // NFT token ID that raised the proposal
    }

    /// @notice A list of all arbitrary transactions proposed by any NFT
    TxProposal[] public txProposals;

    /// @notice Total ETH sacrificed by the ETH account that minted the token ID
    mapping(uint256 => uint256) public tokenIdToAmountSacrificed;

    /// @notice Total number of NFTs that have been issued via sacrificing ETH
    uint256 public totalSupply;

    /// @notice Total amount of ETH currently sacrificed which may be less than the total required
    uint256 public totalSacrificed;

    /// @notice Total sacrifice required before spinning up a validator
    uint256 public immutable SACRIFICE_REQUIRED = 32 ether;

    /// @notice The address of the Stakehouse protocol contract facilitating the on-boarding of the validator
    ITransactionRouter public transactionRouter;

    /// @param _stakehouseTransactionRouter Address of the contract that facilitates onboarding of a validator
    /// @param _initialRepresentative EOA that will assist with the onboarding on behalf of all of the users of the collective
    constructor(ITransactionRouter _stakehouseTransactionRouter, address _initialRepresentative) {
        transactionRouter = _stakehouseTransactionRouter;
        transactionRouter.authorizeRepresentative(_initialRepresentative, true);
    }

    /// @notice Step 1: Sacrifice ETH to Moloch in order to get dETH and SLOT later
    function sacrifice() external payable {
        require(msg.value % 1 gwei == 0, "Sacrifice must be multiple of 1 GWEI");
        require(totalSacrificed + msg.value <= SACRIFICE_REQUIRED, "Exceeded required sacrifice");

        totalSacrificed += msg.value;
        unchecked { totalSupply += 1; }
        tokenIdToAmountSacrificed[totalSupply] = msg.value;

        _mint(msg.sender, totalSupply);
    }

    /// @notice Step 2: Register the validator credentials before doing the deposit
    function registerValidatorInitials(
        uint256 _tokenId,
        bytes calldata _blsPublicKey,
        bytes calldata _blsSignature
    ) public {
        require(totalSacrificed == SACRIFICE_REQUIRED, "Moloch requires more sacrifice");
        require(ownerOf(_tokenId) == msg.sender || transactionRouter.userToRepresentativeStatus(address(this), msg.sender), "Only moloch NFT owner or representative");
        transactionRouter.registerValidatorInitials(
            address(this), _blsPublicKey, _blsSignature
        );
    }

    /// @notice Step 3: Register the validator and send 32 ETH to the EF deposit contract
    function registerValidator(
        uint256 _tokenId,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) public {
        require(totalSacrificed == SACRIFICE_REQUIRED, "Moloch requires more sacrifice");
        require(ownerOf(_tokenId) == msg.sender || transactionRouter.userToRepresentativeStatus(address(this), msg.sender), "Only moloch NFT owner or representative");
        transactionRouter.registerValidator{ value: 32 ether }(
            address(this),
            _blsPublicKey,
            _ciphertext,
            _aesEncryptorKey,
            _encryptionSignature,
            _dataRoot
        );
    }

    /// @notice Step 4: Create a Stakehouse registry instead of joining an existing one
    function createStakehouse(
        uint256 _tokenId,
        address _user,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) public {
        require(totalSacrificed == SACRIFICE_REQUIRED, "Moloch requires more sacrifice");
        require(ownerOf(_tokenId) == msg.sender || transactionRouter.userToRepresentativeStatus(address(this), msg.sender), "Only moloch NFT owner or representative");
        transactionRouter.createStakehouse(
            _user,
            _blsPublicKey,
            _ticker,
            _savETHIndexId,
            _eth2Report,
            _reportSignature
        );
    }

    /// @notice Step 4: Join a Stakehouse registry instead of creating one
    function joinStakehouse(
        uint256 _tokenId,
        address _user,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) public {
        require(totalSacrificed == SACRIFICE_REQUIRED, "Moloch requires more sacrifice");
        require(ownerOf(_tokenId) == msg.sender || transactionRouter.userToRepresentativeStatus(address(this), msg.sender), "Only moloch NFT owner or representative");
        transactionRouter.joinStakehouse(
            _user,
            _blsPublicKey,
            _stakehouse,
            _brandTokenId,
            _savETHIndexId,
            _eth2Report,
            _reportSignature
        );
    }

    /// @notice As a Moloch token holder, propose an arbitrary TX to be executed - it can be instantly executed by any NFT for simplicity purposes
    function propose(uint256 _tokenId, address _to, bytes calldata _data, uint256 _value) external {
        require(totalSacrificed == SACRIFICE_REQUIRED, "Moloch requires more sacrifice");
        require(ownerOf(_tokenId) == msg.sender, "Only moloch NFT owner");
        txProposals.push(TxProposal({
                executed: false,
                to: _to,
                data: _data,
                value: _value,
                proposer: _tokenId
            }));

        emit ProposalSubmitted(txProposals.length - 1);
    }

    /// @notice Execute a transaction as an NFT owner
    function execute(uint256 _tokenId, uint256 _proposalId) external {
        require(_proposalId < txProposals.length, "Invalid ID");
        require(ownerOf(_tokenId) == msg.sender, "Only owner");

        TxProposal storage daoTx = txProposals[_proposalId];
        require(!txProposals[_proposalId].executed, "Already executed or was cancelled");

        txProposals[_proposalId].executed = true;
        (bool success,) = daoTx.to.call{value: daoTx.value}(daoTx.data);
        require(success, "TX execution failed");

        emit ProposalExecuted(_proposalId);
    }
}
