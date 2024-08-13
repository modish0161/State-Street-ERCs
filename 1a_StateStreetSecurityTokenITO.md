### Explanation:

1. **ERC-20 Base**: The contract extends the `ERC20` standard from OpenZeppelin to manage fungible tokens.
2. **Pausable and ReentrancyGuard**: Integrated from OpenZeppelin for added security, allowing the owner to pause the contract in emergencies and preventing reentrancy attacks.
3. **ITO Management**:
   - `startITO(uint256 startTime, uint256 endTime)`: Initiates the ITO with a specific duration.
   - `endITO()`: Ends the ITO after the specified duration.
4. **Token Allocation and Claiming**:
   - `allocateTokens(address investor, uint256 amount)`: Allocates tokens to whitelisted investors during the ITO.
   - `claimTokens()`: Allows investors to claim their tokens once the ITO is completed.
5. **Whitelist Management**: Only whitelisted investors can participate in the ITO, ensuring compliance with regulatory requirements.
6. **Security Features**:
   - **Pausable**: Allows the owner to pause operations during emergencies.
   - **ReentrancyGuard**: Prevents reentrancy attacks on critical functions like `claimTokens`.
   - **SafeMath**: Used to prevent overflow/underflow in arithmetic operations.
7. **Events**: Emit important events like ITO start, end, token allocation, and claiming, allowing easy tracking of contract operations.

### Deployment

- **Networks**: Deploy the contract using your preferred network, whether mainnet or testnet.
- **Gas Optimization**: Consider using a gas-optimized deployment script and monitor gas usage during allocation and claiming functions.

### Testing

- **Unit Tests**: Write unit tests using a framework like Truffle or Hardhat to test each function.
- **Integration Tests**: Ensure the contract interacts correctly with other contracts, particularly around token transfers and ITO logic.

This implementation provides a foundation for issuing and managing security tokens via an Initial Token Offering (ITO), adhering to the best practices and standards discussed.

-------------------------------------------------------------------------

To improve the contract for an investment banking context, where security, compliance, and efficiency are paramount, the following refinements can be made:

1. **Gas Optimization**: Reduce unnecessary operations to save gas.
2. **Code Clarity**: Use modern Solidity practices, such as built-in `SafeMath` in Solidity 0.8.x, instead of the external library.
3. **Compliance & Governance**: Add more granular access control and implement an emergency stop mechanism to halt operations in a crisis.
4. **Immutable Variables**: Use `immutable` for variables that should not change after contract deployment.
5. **Structs for Allocation**: Enhance the readability and extensibility of the allocation mechanism by using a struct.
6. **Detailed Documentation**: Provide more detailed comments for each function, especially for those that are critical from a security or compliance perspective.

### Key Improvements:

1. **Gas Optimization**: 
   - Removed `SafeMath` as Solidity 0.8.x has built-in overflow and underflow protection.
   - Use of `immutable` for `totalSupplyCap` to save gas by ensuring this value can’t be changed after deployment.

2. **Compliance & Governance**:
   - **Whitelist Function**: Added a check to ensure that the investor’s address is valid.
   - **Claiming Tokens**: Now includes a check to prevent double claims by setting a `claimed` flag.

3. **Struct for Allocations**:
   - A struct `Allocation` is used to track both the amount and whether the tokens have been claimed. This makes it easier to manage and extend the logic if needed in the future.

4. **Granular Access Control**:
   - Functions like `whitelistInvestor` and `emergencyWithdraw` include checks to prevent invalid operations and secure against potential misconfigurations.

5. **Detailed Documentation**:
   - Improved comments in critical parts of the contract for better maintainability and understanding of logic, especially useful for auditing purposes.

This contract is now more optimized, secure, and easier to maintain, making it better suited for an investment banking environment where high standards of reliability and security are required.