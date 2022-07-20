# savETH Index Marketplace

This document assumes knowledge of dETH and the savETH registry.

On-chain Marketplaces can be built around the trading of savETH index rates and rights. When the savETH associated with a KNOT is part of an index it has exclusive rights to 100% of the consensus inflation rewards which can be traded. An index of isolated knots can also be traded in a single transaction creating interesting trading activity. 

`savETHIndexMarketplace.sol` offers an insight into how such a marketplace might be built. Using the approval without escrow approach (buying relies on approval to still be active), the example contract makes it possible for users to:
- List an entire index of KNOTs and their assets for sale (gaining rights to exclusive rewards for all knots)
- List a single KNOT's asset and rate for sale
- Buy an index if it's still approved
- Buy a single knot within an index transferring it to an index specified by a buyer

Note: There is no trading in and out of the open index with this exact example [(see the arb contract for that)](https://github.com/stakehouse-dev/stakehouse-templates/blob/main/contracts/arb/savETHIndexArb.sol). This only concerns itself with user curated indices and either moving individual knots between indices or moving ownership of an entire index to a new entity.

In order to commercialise such a marketplace, a protocol may inject a commission that would be taken upon the sale of a listed item. In fact, many features can be added as desired the point is to show what actions the buying will trigger and what data structures to work with.

It's important for users of the marketplace to understand how to price their listings. The example marketplace has a minimum listing price of 24 ETH on the basis that is the minimum dETH required for isolating a KNOT's assets and its rates within an index. Of course this goes up with the amount of consensus rewards reported and when listing an entire index, the sum of each KNOT should be added to ensure a fair listing price for the seller. It would be a shame for an index of 3 KNOTs to be sold for the minimum 24 ETH listing price when it should be sold using the following formula:
```
Minimum savETH index book value = ( Num of KNOTs * 24 ETH ) + dETH rewards earned by all knots from live rate
```

Actual value would factor in DCF etc.

The great thing about such a marketplace is that a user that has spun up multiple KNOTs and has been continually adding them into a single index can within a single transaction instantly liquidate their dETH position into ETH allowing them to either walk away with the money or go again for re-staking. 

To test this on Goerli, the address of the savETH registry will be required:
```
savETH Registry: 0x9ef3bb02cada3e332bbaa27cd750541c5ffb5b03
```

which can also be found from the Protocol's Goerli Subgraph:
```
https://thegraph.com/hosted-service/subgraph/bswap-eng/stakehouse-protocol
```
