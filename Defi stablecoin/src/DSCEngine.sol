// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {DecentralizedStableCoin} from "./DecentralizedStableCoin.sol";
import {ReentrancyGuard} from "lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from
    "lib/chainlink-brownie-contracts/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

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

contract DSCEngine is ReentrancyGuard {
    //errors
    error Amount_should_be_more_than_zero();
    error TokenAddressessAndPriceFeedAddressessShouldBeEqual();
    error TokenNotSupported();
    error transactionFailed();
    error HealthFactorIsBelowOne();

    //state variables
    mapping(address token => address priceFeed) private s_priceFeeds;
    mapping(address user => mapping(address tokenaddress => uint256 amount)) private s_CollateralDeposited;
    mapping(address user => uint256 amountDSCminted) private s_DSCMinted;
    address[] private s_Collateraltokens;
    uint256 private constant ADDITIONAL_PRICE_FEED = 1e10;
    uint256 private constant PRECISION = 1e18;
    uint256 private constant LIQUIDATION_THRESHOLD = 50;
    uint256 private constant LIQUIDATION_PRECISION = 100;
    uint256 private constant MIN_HEALTH_FACTOR = 1;

    //events
    event CollateralDeposited(address indexed user, address indexed token, uint256 indexed amount);

    DecentralizedStableCoin private immutable i_dsc;

    //Modifiers
    modifier morethanZero(uint256 _amount) {
        if (_amount == 0) {
            revert Amount_should_be_more_than_zero();
        }
        _;
    }

    modifier isAllowedToken(address token) {
        if (s_priceFeeds[token] == address(0)) {
            revert TokenNotSupported();
        }
        _;
    }

    //functions
    constructor(address[] memory tokenAddressess, address[] memory priceFeedAddressess, address dscAddress) {
        if (tokenAddressess.length != priceFeedAddressess.length) {
            revert TokenAddressessAndPriceFeedAddressessShouldBeEqual();
        }
        for (uint256 i = 0; i < tokenAddressess.length; i++) {
            s_priceFeeds[tokenAddressess[i]] = priceFeedAddressess[i];
            s_Collateraltokens.push(tokenAddressess[i]);
        }
        i_dsc = DecentralizedStableCoin(dscAddress);
    }

    //external functions

    function depositCollateralAndMintDSC() external {}

    /*
    *@notice follows CEI
    *@param tokenCollateralAddress: The address of the token to be deposited as collateral
    *@param amountCollateral: The amount of collateral to be deposited
    */
    function depositCollateral(address tokenCollateralAddress, uint256 amountCollateral)
        external
        morethanZero(amountCollateral)
        isAllowedToken(tokenCollateralAddress)
        nonReentrant
    {
        s_CollateralDeposited[msg.sender][tokenCollateralAddress] += amountCollateral;
        emit CollateralDeposited(msg.sender, tokenCollateralAddress, amountCollateral);
        bool success = IERC20(tokenCollateralAddress).transferFrom(msg.sender, address(this), amountCollateral);
        if (!success) {
            revert transactionFailed();
        }
    }

    function redeemCollateralForDSC() external {}

    function redeemCollateral() external {}

    /*
    *@notice follows CEI
    *@param amountDscToMint: The amount of DSC to mint
    */
    function mintDSC(uint256 amountDscToMint) external morethanZero(amountDscToMint) nonReentrant {
        s_DSCMinted[msg.sender] += amountDscToMint;
        _revertifHealthfactorisBroken(msg.sender);
        bool minted = i_dsc.mint(msg.sender, amountDscToMint);
        if (!minted) {
            revert transactionFailed();
        }
    }

    function burnDSC() external {}

    function liquidate() external {}

    function getHealthFactor() external {}

    //private functions
    function _Getaccountinfo(address user) private view returns (uint256 TotalDSCMinted, uint256 collateralTotalUsd) {
        TotalDSCMinted = s_DSCMinted[user];
        collateralTotalUsd = getAccountCollateralValueinUsd(user);
    }
    /*
    *Returns how close a user is to liquidation 
    *If a user goes below 1, they can get  liquidated
    */

    function _healthFactor(address user) private view returns (uint256) {
        (uint256 totalDSCMinted, uint256 totalDSCValueinUsd) = _Getaccountinfo(user);
        uint256 collateraladjustedforthreshold = (totalDSCValueinUsd * LIQUIDATION_THRESHOLD) / LIQUIDATION_PRECISION;
        return (collateraladjustedforthreshold * PRECISION) / totalDSCMinted;
    }

    function _revertifHealthfactorisBroken(address user) internal view {
        if (_healthFactor(user) < MIN_HEALTH_FACTOR) {
            revert HealthFactorIsBelowOne();
        }
    }

    //public functions
    function getAccountCollateralValueinUsd(address user) public view returns (uint256 totalcollateralvalueinusd) {
        for (uint256 i = 0; i < s_Collateraltokens.length; i++) {
            address token = s_Collateraltokens[i];
            uint256 amount = s_CollateralDeposited[user][token];
            totalcollateralvalueinusd += getUSDvalue(token, amount);
        }
        return totalcollateralvalueinusd;
    }

    function getUSDvalue(address token, uint256 amount) public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(s_priceFeeds[token]);
        (, int256 price,,,) = priceFeed.latestRoundData();
        return ((ADDITIONAL_PRICE_FEED * uint256(price)) * amount) / PRECISION;
    }
}
