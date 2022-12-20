# Tokenized Mutual Fund
![Build status](https://github.com/bthreader/tokenized-mutual-fund/actions/workflows/ci.yml/badge.svg)

All documentation for my UCL MSc CompSci thesis titled "Tokenizing Mutual Funds on the Ethereum Blockchain". 

Developed using the [foundry](https://getfoundry.sh/) toolkit.

## Achievements
The objective of the research was to implement two realistic, fully functioning mutual fund tokens:
* One for a fund with a portfolio of off-chain assets *(src/fund/OffChainFund.sol)*
* One for a fund with a portfolio of on-chain assets *(src/fund/InvestedFund.sol.)*

### Highlights:
1. Off-chain fund guaranteed buyers liquidity 24/7 at NAVPS. Sellers were offered guaranteed liquidity daily and potential liquidity 24/7 again at NAVPS. This was handled by a sell order queue thus facilitating peer to peer trading through the contract (shown below).

```mermaid
flowchart LR
    A(Client places buy order) --> B{Sell orders outstanding?} 
    B --> |No| C(Currency moved into the contract\n and share ownership adjusted)
    B --> |Yes| D(Forward currency to seller\n and transfer ownership)
    D -->|All sell orders executed and \n client can afford more shares| C
```

2. On-chain fund rebalanced itself according to an investment strategy provided by the fund manager upon contract construction, and guaranteed liqudity to buyers and sellers 24/7 by adjusting investment positions.

*Please find the full thesis in Dissertation.pdf.*