# DODOMarginTrading contest details

- Users can create their own MarginTrading contracts through the MarginTradingFactory for leveraged trading, deposit funds, and open positions.
- MarginTrading contracts enable users to perform various operations such as opening, partially or fully closing positions, and adjusting margin levels, all executed through Aave.
- To open a position, users can borrow funds using Aave flash loans, swap them for the desired token, and then deposit the long token into Aave to meet its requirements. The flash loan is then converted to a long-term loan.
- To close a position, users can swap their Aave assets and use their debtToken balance to repay the loan. Any excess funds will be returned to the user, and the corresponding assets will be withdrawn from Aave and returned to the flash loan.
- When partially closing a position, users can swap their Aave assets and use the swap-out token quantity to repay the loan. However, there is a possibility of partial closure failing due to slippage or the swap-out token quantity being greater than the debt token quantity. Such occurrences are rare and can be ignored.
- Increasing margin involves depositing funds into Aave through DODOApprove and DODOApproveProxy, which are authorized for transfer in the MarginTradingFactory contract.
- Decreasing margin involves withdrawing funds from Aave, converting any WETH assets back to their native assets, and transferring them back to the user. Other ERC20 tokens are not affected and will be transferred back to the user unchanged.

# Resources

- [Docs]()
- [DODOMarginTrading Contracts ](https://github.com/DODOEX/dodo-margin-trading-contracts/tree/main/contracts/marginTrading)
- [Smart Contract Overview]()

# Setup instructions:
- `yarn`
- `forge test`
