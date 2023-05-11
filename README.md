
# DODO Margin Trading contest details

- Users can create their own MarginTrading contracts through the MarginTradingFactory for leveraged trading, deposit funds, and open positions.
- MarginTrading contracts enable users to perform various operations such as opening, partially or fully closing positions, and adjusting margin levels, all executed through Aave.
- To open a position, users can borrow funds using Aave flash loans, swap them for the desired token, and then deposit the long token into Aave to meet its requirements. The flash loan is then converted to a long-term loan.
- To close a position, users can swap their Aave assets and use their debtToken balance to repay the loan. Any excess funds will be returned to the user, and the corresponding assets will be withdrawn from Aave and returned to the flash loan.
- When partially closing a position, users can swap their Aave assets and use the swap-out token quantity to repay the loan. However, there is a possibility of partial closure failing due to slippage or the swap-out token quantity being greater than the debt token quantity. Such occurrences are rare and can be ignored.
- Increasing margin involves depositing funds into Aave through DODOApprove and DODOApproveProxy, which are authorized for transfer in the MarginTradingFactory contract.
- Decreasing margin involves withdrawing funds from Aave, converting any WETH assets back to their native assets, and transferring them back to the user. Other ERC20 tokens are not affected and will be transferred back to the user unchanged.


- Join [Sherlock Discord](https://discord.gg/MABEWyASkp)
- Submit findings using the issue page in your private contest repo (label issues as med or high)
- [Read for more details](https://docs.sherlock.xyz/audits/watsons)

# Q&A

### Q: On what chains are the smart contracts going to be deployed?
mainnet、polygon
___

### Q: Which ERC20 tokens do you expect will interact with the smart contracts? 
WETH USDC WBTC DAI MATIC
___

### Q: Which ERC721 tokens do you expect will interact with the smart contracts? 
none
___

### Q: Which ERC777 tokens do you expect will interact with the smart contracts? 
none
___

### Q: Are there any FEE-ON-TRANSFER tokens interacting with the smart contracts?

none
___

### Q: Are there any REBASING tokens interacting with the smart contracts?

none
___

### Q: Are the admins of the protocols your contracts integrate with (if any) TRUSTED or RESTRICTED?
RESTRICTED
___

### Q: Is the admin/owner of the protocol/contracts TRUSTED or RESTRICTED?
RESTRICTED
___

### Q: Are there any additional protocol roles? If yes, please explain in detail:
There is a proxy role that has permissions stored in the ALLOWED_FLASH_LOAN structure. This role can execute opening or closing positions on behalf of the user to achieve stop loss or take profit objectives.
___

### Q: Is the code/contract expected to comply with any EIPs? Are there specific assumptions around adhering to those EIPs that Watsons should be aware of?
none
___

### Q: Please list any known issues/acceptable risks that should not result in a valid finding.
In some partial closure cases, if a limit value is reached, such as closing 99.99% of the position, the final swap out token may exceed the expected amount due to on-chain slippage, resulting in a failed closure. This is because in partial closures, the closure is based on the swap out token amount, while full closure is based on the debt amount. In the scenario just described, the swap out token amount is greater than the debt amount, resulting in the failure.
___

### Q: Please provide links to previous audits (if any).
none
___

### Q: Are there any off-chain mechanisms or off-chain procedures for the protocol (keeper bots, input validation expectations, etc)?
none
___

### Q: In case of external protocol integrations, are the risks of external contracts pausing or executing an emergency withdrawal acceptable? If not, Watsons will submit issues related to these situations that can harm your protocol's functionality.
Acceptable to take on the risks of external contracts pausing or executing an emergency withdrawal.
___



# Audit scope


[dodo-margin-trading-contracts @ f6279954cdfb48824c5186cbb86a200db2cddff5](https://github.com/DODOEX/dodo-margin-trading-contracts/tree/f6279954cdfb48824c5186cbb86a200db2cddff5)
- [dodo-margin-trading-contracts/contracts/marginTrading/MarginTradingFactory.sol](dodo-margin-trading-contracts/contracts/marginTrading/MarginTradingFactory.sol)
- [dodo-margin-trading-contracts/contracts/marginTrading/Types.sol](dodo-margin-trading-contracts/contracts/marginTrading/Types.sol)
- [dodo-margin-trading-contracts/contracts/marginTrading/MarginTrading.sol](dodo-margin-trading-contracts/contracts/marginTrading/MarginTrading.sol)





