# Curve Lending Bot

## factory.vy

### deploy_curve_lending_bot

This function deploys a bot contract using blueprint.

| Key | Type | Description |
| --- | ---- | ----------- |
| -   | -    | -           |

### add_collateral

This function adds collateral to prevent liquidation. This function is called by Compass-EVM only.

| Key         | Type      | Description                    |
| ----------- | --------- | ------------------------------ |
| bots        | address[] | bots address array             |
| collateral  | address[] | collateral token address array |
| lend_amount | uint256[] | lend collateral amount array   |

### repay

This function repay crvUSD to prevent liquidation. This function is called by Compass-EVM only.

| Key          | Type      | Description                    |
| ------------ | --------- | ------------------------------ |
| bots         | address[] | bots address array             |
| collateral   | address[] | collateral token address array |
| repay_amount | uint256[] | crvUSD amount array to repay   |

### *_event

These functions are to emit events in the factory contract, not in bot contract so that fetching all events from this bots easier.

### health

This function returns health value. This is a view function.

| Key        | Type    | Description                  |
| ---------- | ------- | ---------------------------- |
| collateral | address | collateral token address     |
| bot        | address | bot address                  |
| **Return** | int256  | Returns health of collateral |

### loan_exists

This function returns true if loan exists. This is a view function.

| Key        | Type    | Description                                      |
| ---------- | ------- | ------------------------------------------------ |
| collateral | address | collateral token address                         |
| bot        | address | bot address                                      |
| **Return** | bool    | Returns true when loan for the collateral exists |

### collateral_reserves

This function returns token balance of the bot. This is a view function.

| Key        | Type    | Description                      |
| ---------- | ------- | -------------------------------- |
| collateral | address | collateral token address         |
| bot        | address | bot address                      |
| **Return** | uint256 | Returns token balance of the bot |

### state

This function returns loan state. This is a view function.

| Key        | Type       | Description                       |
| ---------- | ---------- | --------------------------------- |
| collateral | address    | collateral token address          |
| bot        | address    | bot address                       |
| **Return** | uint256[4] | [collateral, stablecoin, debt, N] |

### update_compass

Update Compass-EVM address.  This is run by Compass-EVM only.

| Key         | Type    | Description             |
| ----------- | ------- | ----------------------- |
| new_compass | address | New compass-evm address |

### update_refund_wallet

Update gas refund wallet address.  This is run by Compass-EVM only.

| Key               | Type    | Description               |
| ----------------- | ------- | ------------------------- |
| new_refund_wallet | address | New refund wallet address |

### update_fee

Update gas fee amount to pay.  This is run by Compass-EVM only.

| Key     | Type    | Description    |
| ------- | ------- | -------------- |
| new_fee | uint256 | New fee amount |

### set_paloma

Set Paloma CW address in bytes32.  This is run by Compass-EVM only and after setting paloma, the bot can start working.

| Key | Type | Description |
| --- | ---- | ----------- |
| -   | -    | -           |

### update_service_fee_collector

Update service fee collector address.  This is run by the original fee collector address. The address receives service fee from swapping.

| Key                       | Type    | Description                       |
| ------------------------- | ------- | --------------------------------- |
| new_service_fee_collector | address | New service fee collector address |


## curve_lending_bot.vy

### create_loan

This function creates a loan using collateral. This can be done only once.

| Key               | Type    | Description                                                     |
| ----------------- | ------- | --------------------------------------------------------------- |
| collateral        | address | collateral token address                                        |
| collateral_amount | uint256 | collateral token amount to put into the bot                     |
| lend_amount       | uint256 | collateral amount to lend from the bot to Curve pool            |
| debt              | uint256 | crvUSD amount to borrow from Curve pool to the bot              |
| withdraw_amount   | uint256 | crvUSD amount to withdraw from the bot                          |
| N                 | uint256 | number of bands the deposit is made into of Curve pool          |
| health_threshold  | int256  | health threshold to trigger bot to reduce risk                  |
| expire            | uint256 | expire timestamp of the bot                                     |
| repayable         | bool    | option bool to determine repay or add_collateral to reduce risk |

### add_collateral_with_swap

This function adds collateral from a user with Curve swap so that any kind of token can be used.

| Key         | Type       | Description                                          |
| ----------- | ---------- | ---------------------------------------------------- |
| swap_infos  | SwapInfo[] | Curve swap info                                      |
| lend_amount | uint256    | collateral amount to lend from the bot to Curve pool |

### add_collateral

This function adds collateral to reduce risk. Users can Compass-EVM can run it. Compass-EVM can run with collateral_amount = 0 because Compass-EVM isn't allowed to move tokens from users to the bot.

| Key               | Type    | Description                                          |
| ----------------- | ------- | ---------------------------------------------------- |
| collateral        | address | collateral token address                             |
| collateral_amount | uint256 | collateral token amount to put into the bot          |
| lend_amount       | uint256 | collateral amount to lend from the bot to Curve pool |

### remove_collateral

This function adds collateral to reduce risk. Users can Compass-EVM can run it. Compass-EVM can run with collateral_amount = 0 because Compass-EVM isn't allowed to move tokens from users to the bot.

| Key               | Type    | Description                                           |
| ----------------- | ------- | ----------------------------------------------------- |
| collateral        | address | collateral token address                              |
| collateral_amount | uint256 | collateral token amount to remove from the Curve pool |
| withdraw_amount   | uint256 | collateral amount to lend from the bot to Curve pool  |

### borrow_more

This function borrows more crvUSD from the Curve pool. Users can run it.

| Key               | Type    | Description                                          |
| ----------------- | ------- | ---------------------------------------------------- |
| collateral        | address | collateral token address                             |
| collateral_amount | uint256 | collateral token amount to put more into the bot     |
| lend_amount       | uint256 | collateral amount to lend from the bot to Curve pool |
| debt              | uint256 | crvUSD amount to lend more from the Curve pool       |
| withdraw_amount   | uint256 | crvUSD amount to withdraw from the bot to users      |

### repay

This function repays crvUSD to reduce risk.

| Key          | Type    | Description                                       |
| ------------ | ------- | ------------------------------------------------- |
| collateral   | address | collateral token address                          |
| input_amount | uint256 | crvUSD amount to put into the bot                 |
| repay_amount | uint256 | crvUSD amount to repay from the bot to Curve pool |

### cancel

This function cancels a bot. It moves required crvUSD amount from the user and repays all debt, and removes all collateral, sends it to the user.

| Key        | Type    | Description              |
| ---------- | ------- | ------------------------ |
| collateral | address | collateral token address |

### withdraw_crvusd

This function sends crvUSD from the bot to the user.

| Key    | Type    | Description                                    |
| ------ | ------- | ---------------------------------------------- |
| amount | uint256 | crvUSD amount to send from the bot to the user |

### bot_restart

This function emits an event to let backend know that the user wants to restart the bot. This can be used to change the bot configurations.

| Key              | Type    | Description                                                     |
| ---------------- | ------- | --------------------------------------------------------------- |
| collateral       | address | collateral token address                                        |
| health_threshold | int256  | health threshold to trigger bot to reduce risk                  |
| expire           | uint256 | expire timestamp of the bot                                     |
| repayable        | bool    | option bool to determine repay or add_collateral to reduce risk |

### health

This function returns health value. This is a view function.

| Key        | Type    | Description                  |
| ---------- | ------- | ---------------------------- |
| collateral | address | collateral token address     |
| **Return** | int256  | Returns health of collateral |

### loan_exists

This function returns true if loan exists. This is a view function.

| Key        | Type    | Description                                      |
| ---------- | ------- | ------------------------------------------------ |
| collateral | address | collateral token address                         |
| **Return** | bool    | Returns true when loan for the collateral exists |

### state

This function returns loan state. This is a view function.

| Key        | Type       | Description                       |
| ---------- | ---------- | --------------------------------- |
| collateral | address    | collateral token address          |
| **Return** | uint256[4] | [collateral, stablecoin, debt, N] |
