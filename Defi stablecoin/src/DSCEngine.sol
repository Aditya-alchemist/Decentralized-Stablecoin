// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

/*
 * @title DSCEngine
 * @author Aditya kumar Mishra
 *
 * The system is designed to be as minimal as possible, and have the tokens maintain a 1 token == $1 peg at all times.
 * This is a stablecoin with the properties:
 * - Exogenously Collateralized
 * - Dollar Pegged
 * - Algorithmically Stable
 *
 * It is similar to DAI if DAI had no governance, no fees, and was backed by only WETH and WBTC.
 *
 * Our DSC system should always be "overcollateralized". At no point, should the value of
 * all collateral < the $ backed value of all the DSC.
 *
 * @notice This contract is the core of the Decentralized Stablecoin system. It handles all the logic
 * for minting and redeeming DSC, as well as depositing and withdrawing collateral.
 * @notice This contract is based on the MakerDAO DSS system
 */

contract DSCEngine {

    //errors
    error Amount_should_be_more_than_zero();

    //Modifiers
    modifier morethanZero(uint256 _amount) {
       if(_amount==0){
        revert Amount_should_be_more_than_zero();
       }
       _;
    }


    //functions
   constructor() public{}

   //external functions

   


    function depositCollateralAndMintDSC()  external{}

    /*
    *@param tokenCollateralAddress: The address of the token to be deposited as collateral
    *@param amountCollateral: The amount of collateral to be deposited
    */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral) external
     morethanZero(amountCollateral){

     }

    function redeemCollateralForDSC() external{}

    function redeemCollateral() external {}

    function mintDSC() external{}

    function burnDSC() external{}

    function liquidate() external{}

    function getHealthFactor() external{}

}