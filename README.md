# Stakehouse Protocol Smart Contract Templates 🏗️

This repository contains examples of how to use deployable templates to build:
- Yield generating protocols
- ETH Pooling mechanisms for bootstrapping the 32 ETH staking requirement
- Gate keeping 
- Representative staking for DAOs and other multi-signature treasuries
- Fractionalization (ERC20, ERC721, ERC1155 etc.)
- Sniping arb bots

And many more...

These contracts have not been audited and merely offer integration points into the Stakehouse protocol. Use at own risk

Extensive data from the Goerli smart cotract subgraph can be found here:
```
https://thegraph.com/hosted-service/subgraph/bswap-eng/stakehouse-protocol
```

Here are some of the Goerli smart contracts to get started:
```
savETH Registry Router: 0x9ef3bb02cada3e332bbaa27cd750541c5ffb5b03
Transaction Router: 0xc4b44383c15e4afed9845393b215a75d44d3d24b
```

## Next Generation Multi-chain Money Markets 🏦

The next generation of money markets will be powered by multi-chain ETH earning perpetual yield from the consensus layer. This yield is programmable and can be re-packaged and re-marketed in many ways.

Only focusing on the tip of the iceberg, the following is possible:
- Fixed yield ETH savings accounts that can be offered to any dETH holder
- Self repaying loans taken out against dETH
- Re-packaged yield from savETH that can be issued as new tokens and then those LP tokens leveraged in any way possible

In time, more and more documentation around the programmable yield layer: savETH Registry. Besides offering a way for users to claim their dETH inflation rewards, it allows the curation of savETH shares (representing a claim on dETH) and any savETH index. A savETH index itself is a way of grouping knots together in order to offer earn aggregated yield and thus spreading assets across different KNOTs which of course can be fractionalized and offered out to other users...  

The yield protocol contract that can be found within [`contracts/yield`](./contracts/yield) folder along with a handy script to calculate savETH index yield.

## Gate Keeping ✋

If you are the creator of a Stakehouse or owner of a brand, you can control which validator KNOTs can join your collective by creating and deploying your own gate keeper.

You can find an off the shelf deployable contract within the [`contracts/gate-keeping`](./contracts/gate-keeping) folder.

It is an OZ `Ownable` contract that offers very granular control. 

Any form of customisation is possible for example:
- Using an external contract to make the decision
- Using a merkle tree

And more. The merkle tree option is interesting. Imagine you are an entity that requires performing KYC before adding a KNOT to your Stakehouse. You may do a large batch of KYC checks and afterwards, update the merkle tree of the gate keeper allowing all entities that have passed KYC to enter the house and start earning yield!

## DAO Treasury Management with ERC721 NFT Receipts 💰

Suppose that a group of `n` participants (minimum being 1) want to deploy their ETH in order to meet the 32 ETH requirement to stake via the Ethereum Foundation Deposit Contract; perhaps they wish to do this via the Stakehouse protocol.

An Ethereum account can do the deposit, or deposits can be done with smart contracts via the representative functionality offered by the Stakehouse protocol. A representative is an Ethereum EOA that handles the entire validator onboarding process on behalf of another user or smart contract where that user does not need to give up ownership of the Stakehouse protocol derivatives. Essentially, a representative allows someone with capital (Ether) to stake without any technical staking knowledge thus enabling all sorts of one click staking applications. See representative explanation in another section below. 

With all this in mind, a pooling smart contract can be built in order to accumulate ETH and then follow the steps required to register a validator within the Stakehouse protocol. 

### 👹 Enter Moloch 👺 

You can find an off the shelf deployable contract within the [`contracts/treasury`](./contracts/treasury) folder.

Being Moloch, it requires a sacrifice of any amount of Ether from all participants. In exchange for each sacrifice an NFT is minted representing the sacrifice. Once the full 32 Ether sacrifice is achieved, the onboarding process can start where each user's sacrifice (recorded within their NFT) can be rewarded with derivatives proportionally. 

Going back to the stage where the 32 ETH deposit is successfully completed, the NFTs represent the tokenization of future derivatives and therefore can be traded at a premium to the base Ether injected at the start because at some point those derivatives will start generating yield! Extending this further, a single sacrifice of the full 32 ether would mint a single NFT which would mean being able to sell all 24 dETH and 8 SLOT derivatives as an NFT. There are endless possibilities here...

### Representatives
Categories of representatives:
- Sponsorship (User does some actions off chain but gets transaction GAS sponsorship (in the case of the community faucet it even pays for the user's 32 ETH staking costs!))
- Smart contract supported operations (Smart contract like a DAO does on-chain operations but delegates off-chain interactions such as with router to representative that operates under an EOA)
- Representative-operated contracts (User places funds in a contract that they control but representative does both on-chain and off-chain interactions. An escrow with special spending conditions)
- Centralised representative (User delegates everything to a single EOA controlled by an exchange which will do everything from start to finish but will send the users derivatives at some point. The centralised exchange is already in custody of their ETH. The only thing a user has to do is a one time on-chain operation approving the exchange and the exchange can take care of the rest)

So we have a triangle of entities: Derivative recipient, the funder (of the validator) and the executor (of actions). They may all be the same or it may be split in unique ways.