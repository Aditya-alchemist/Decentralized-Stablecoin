# DSCEngine Contract - Detailed Documentation

## Table of Contents
1. [Introduction](#introduction)
2. [System Architecture & Features](#system-architecture--features)
3. [Dependencies and Requirements](#dependencies-and-requirements)
4. [Contract Overview](#contract-overview)
5. [Core Functionalities](#core-functionalities)
    - [Collateral Management](#collateral-management)
    - [Minting & Burning DSC](#minting--burning-dsc)
    - [Liquidation Process](#liquidation-process)
6. [State Variables & Modifiers](#state-variables--modifiers)
7. [Error Handling](#error-handling)
8. [Security Considerations](#security-considerations)
9. [Deployment and Configuration](#deployment-and-configuration)
11. [Contributing & Future Enhancements](#contributing--future-enhancements)
12. [License](#license)
13. [Conclusion](#conclusion)

---

## Introduction

The DSCEngine contract is the backbone of a decentralized stablecoin system designed to maintain a peg of 1 DSC token to 1 USD. Inspired by MakerDAO’s DSS system, this implementation focuses on simplicity and minimalism while ensuring overcollateralization. It supports multiple collateral types (e.g., WETH and WBTC) and uses Chainlink price feeds to guarantee that the value of deposited collateral exceeds the DSC issued at all times.

The contract employs modern Solidity practices (version 0.8.28) and leverages established libraries such as OpenZeppelin for security (ReentrancyGuard and IERC20) and Chainlink for reliable external price feeds. NatSpec comments are used throughout the code to enhance readability and maintainability.

---

## System Architecture & Features

### Key Features

- **Exogenously Collateralized:**  
  Users deposit ERC20 tokens as collateral which backs the issuance of the DSC tokens.

- **Algorithmically Stable:**  
  The system automatically adjusts through overcollateralization, ensuring that the collateral value always exceeds the total DSC minted.

- **Dollar Pegged:**  
  Each DSC token is pegged to $1, achieved by continuously monitoring and adjusting the collateral through a health factor.

- **Liquidation Mechanism:**  
  In the event of undercollateralization (health factor dropping below 1), external parties can liquidate the position to help restore system stability. Liquidators are rewarded with a bonus collateral incentive.

- **Reentrancy Protection:**  
  By using OpenZeppelin’s `ReentrancyGuard`, the contract is safeguarded against reentrancy attacks.

- **Chainlink Integration:**  
  The contract integrates with Chainlink price feeds using the `AggregatorV3Interface` to retrieve real-time price data for collateral assets.

---

## Dependencies and Requirements

Before deploying the DSCEngine contract, ensure you have the following dependencies:

- **Solidity Compiler:** Version 0.8.28.
- **OpenZeppelin Contracts:** For `ReentrancyGuard` and `IERC20` functionality.
- **Chainlink Brownie Contracts:** For `AggregatorV3Interface` to fetch up-to-date collateral prices.
- **DecentralizedStableCoin Contract:** A separate contract responsible for the minting and burning of DSC tokens.
- **OracleLib:** A custom library that extends functionality for handling price feeds and oracle interactions.

The contract relies on matching arrays of collateral token addresses and their respective price feed addresses during initialization.

---

## Contract Overview

The DSCEngine contract is responsible for managing the lifecycle of the DSC stablecoin through a series of functions that allow for:

- **Collateral Deposits:** Users deposit supported ERC20 tokens.
- **DSC Minting:** Users can mint DSC tokens based on the collateral deposited.
- **Collateral Redemption:** Users redeem collateral by burning DSC tokens.
- **Liquidation:** Allows third parties to liquidate positions where the user’s collateralization ratio falls below the required threshold.

The contract follows the Checks-Effects-Interactions (CEI) pattern, ensuring that state changes occur before external calls. This design minimizes vulnerabilities and maintains system integrity.

---

## Core Functionalities

### Collateral Management

**Depositing Collateral:**  
Users deposit collateral via the `depositCollateral` function, which first validates that the amount is greater than zero and that the token is supported (using the `isAllowedToken` modifier). Once validated, the token amount is transferred from the user to the contract, and an event is emitted to record the deposit.

**Redeeming Collateral:**  
To redeem collateral, users call the `redeemCollateralForDSC` function. This function requires users to burn DSC tokens equivalent to the amount of collateral they wish to withdraw. The internal function `_redeemCollateral` then handles the safe transfer of tokens back to the user, ensuring that the health factor remains within safe limits post-withdrawal.

### Minting & Burning DSC

**Minting DSC:**  
The `mintDSC` function allows users to mint DSC tokens against their deposited collateral. The amount of DSC minted increases the user’s debt, and the contract immediately verifies that the user’s health factor remains above the minimum required threshold. If the health factor falls below the safe limit, the transaction reverts.

**Burning DSC:**  
Conversely, the `burnDSC` function reduces the user’s debt by burning a specified amount of DSC tokens. The burning process includes transferring DSC tokens from the user to the contract and then calling the internal burn mechanism on the DSC contract. This operation also rechecks the user’s health factor after the burn.

### Liquidation Process

The liquidation function is critical for maintaining system stability. If a user’s health factor drops below 1, external liquidators can cover part of the user’s debt by burning DSC tokens on their behalf. In exchange, the liquidator receives the equivalent collateral along with a bonus incentive. The function `liquidate` calculates the amount of collateral based on current price feeds and applies a bonus percentage (defined by `LIQUIDATION_BONOUS`). This process ensures that undercollateralized positions are promptly addressed.

---

## State Variables & Modifiers

### State Variables

- **s_priceFeeds:**  
  A mapping that links each collateral token address to its corresponding Chainlink price feed.

- **s_CollateralDeposited:**  
  Tracks the amount of collateral deposited by each user for each supported token.

- **s_DSCMinted:**  
  Records the total DSC minted by each user.

- **s_Collateraltokens:**  
  An array that holds all supported collateral token addresses.

- **Constants:**  
  Variables such as `ADDITIONAL_PRICE_FEED`, `PRECISION`, `LIQUIDATION_THRESHOLD`, `MIN_HEALTH_FACTOR`, and `LIQUIDATION_BONOUS` define system parameters used for calculations related to collateral valuation, liquidation thresholds, and bonus incentives.

### Modifiers

- **morethanZero:**  
  Ensures that input amounts (for deposits, withdrawals, and DSC minting/burning) are greater than zero.

- **isAllowedToken:**  
  Checks whether a given token is supported by verifying its presence in the s_priceFeeds mapping.

- **nonReentrant:**  
  Provided by OpenZeppelin’s ReentrancyGuard to prevent reentrant calls.

---

## Error Handling

The DSCEngine contract defines custom error types to provide clear feedback during transaction failures. These include:

- **Amount_should_be_more_than_zero:**  
  Triggered when a function call is made with a zero amount.

- **TokenAddressessAndPriceFeedAddressessShouldBeEqual:**  
  Ensures that the arrays of token addresses and price feed addresses are of equal length during initialization.

- **TokenNotSupported:**  
  Reverts the transaction if a user attempts to interact with an unsupported token.

- **transactionFailed:**  
  A generic error that is thrown when a token transfer or minting/burning operation fails.

- **HealthFactorIsBelowOne / HealthFactorIsNOTBELOWONE:**  
  These errors ensure that critical health factor checks are enforced to prevent undercollateralization or invalid liquidation attempts.

---

## Security Considerations

- **Reentrancy Protection:**  
  The use of `nonReentrant` ensures that external calls cannot lead to reentrancy attacks, safeguarding user funds and contract state.

- **Health Factor Checks:**  
  Continuous verification of the user’s health factor ensures that the system remains overcollateralized. Any transaction that would lead to an unsafe state is automatically reverted.

- **Oracle Price Feeds:**  
  By integrating Chainlink oracles, the contract relies on decentralized and secure price feeds, reducing the risk of price manipulation.

- **Error Propagation:**  
  Custom errors provide transparency, making it easier to identify issues during debugging and audits.

---

## Deployment and Configuration

### Pre-Deployment Setup

1. **Prepare the Environment:**  
   Ensure you have the correct version of the Solidity compiler (0.8.28) and install all required dependencies from OpenZeppelin and Chainlink repositories.

2. **Contract Parameters:**  
   - Provide two arrays during deployment: one containing the supported collateral token addresses and another containing the corresponding Chainlink price feed addresses.  
   - Supply the address of the deployed DecentralizedStableCoin contract.

### Deployment Steps

- Compile the DSCEngine contract using your preferred Solidity development environment (e.g., Hardhat, Truffle).
- Deploy the contract to your target network (local, testnet, or mainnet) while ensuring that all dependencies are correctly configured.
- Verify the deployment by checking that the contract’s state variables (such as supported tokens and price feeds) are correctly initialized.

---


### Development Best Practices

- Follow the CEI (Checks-Effects-Interactions) pattern rigorously.
- Regularly audit the code and update dependencies to minimize security risks.
- Maintain thorough NatSpec documentation to aid future developers and auditors.

---

## Contributing & Future Enhancements

Contributions to the DSCEngine project are welcome. Potential areas for improvement include:

- **Supporting Additional Collateral Types:**  
  Expanding the system to include more types of collateral, thereby increasing flexibility.

- **Enhanced Liquidation Mechanisms:**  
  Developing more robust liquidation strategies to handle extreme market conditions.

- **User Interface Development:**  
  Building a front-end application that interacts seamlessly with the DSCEngine contract for easier user interaction.

- **Optimizations:**  
  Continuous code optimizations for gas efficiency and performance improvements.

To contribute, please fork the repository, create a feature branch, and submit a pull request with detailed explanations of your changes.

---

## License

This project is licensed under the terms specified in the [LICENSE](./LICENSE) file. Please review the license for more information about how you can use and distribute this code.

---

## Conclusion

The DSCEngine contract represents a robust and minimalist approach to creating a decentralized stablecoin system. By ensuring overcollateralization through continuous health factor checks and using reliable Chainlink price feeds, the system offers a secure, efficient, and transparent means to mint and manage DSC tokens. Whether you are a developer looking to build on this framework or an auditor seeking to understand its inner workings, this documentation provides a comprehensive overview of its design, functionality, and intended usage.

For any further questions or contributions, please refer to the project's repository and documentation, and feel free to reach out to the development team.

Built by- Aditya kumar Mishra
