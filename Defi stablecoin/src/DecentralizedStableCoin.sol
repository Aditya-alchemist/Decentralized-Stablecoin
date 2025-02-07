// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {ERC20, ERC20Burnable} from "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

/*
 * @title DecentralizedStableCoin
 * @author Aditya kumar Mishra
 * Collateral: Exogenous
 * Minting (Stability Mechanism): Decentralized (Algorithmic)
 * Value (Relative Stability): Anchored (Pegged to USD)
 * Collateral Type: Crypto
 *
* This is the contract meant to be owned by DSCEngine. It is a ERC20 token that can be minted and burned by the
DSCEngine smart contract.
 */

contract DecentralizedStableCoin is ERC20Burnable, Ownable {
    constructor() ERC20("Decentralized Stable Coin", "DSC") Ownable(msg.sender) {}

    error DecentralizedStableCoin_MustBeMoreThanZero();
    error DecentralizedStableCoin_MustBeLessThanSupply();
    error DecentralizedStableCoin_Cannotsendtozerothaddress();

    function burn(uint256 _amount) public override onlyOwner {
        uint256 balance = balanceOf(msg.sender);
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }

        if (balance < _amount) {
            revert DecentralizedStableCoin_MustBeLessThanSupply();
        }

        super.burn(_amount);
    }

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (address(0) == _to) {
            revert DecentralizedStableCoin_Cannotsendtozerothaddress();
        }
        if (_amount <= 0) {
            revert DecentralizedStableCoin_MustBeMoreThanZero();
        }
        super._mint(_to, _amount);
        return true;
    }
}
