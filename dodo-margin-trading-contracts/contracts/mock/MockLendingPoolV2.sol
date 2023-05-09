// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import {IFlashLoanReceiver} from "../aaveLib/Interfaces.sol";

contract MockLendingPoolV2 {
    MockERC20 public daiToken;
    MockERC20 public wethToken;

    mapping(address => address) public aToken; //标记存款
    mapping(address => address) public debtToken; //标记借款

    event Withdraw(address asset, address user, address to, uint256 amountToWithdraw);

    event Deposit(address asset, address sender, address onBehalfOf, uint256 amount, uint16 referralCode);

    event Borrow(address asset, address sender, address onBehalfOf, uint256 amount);

    event Repay(address asset, address onBehalfOf, address user, uint256 amount);

    /**
     * @dev Emitted when a borrower is liquidated. This event is emitted by the LendingPool via
     * LendingPoolCollateral manager using a DELEGATECALL
     * This allows to have the events in the generated ABI for LendingPool.
     * @param collateralAsset The address of the underlying asset used as collateral, to receive as result of the liquidation
     * @param debtAsset The address of the underlying borrowed asset to be repaid with the liquidation
     * @param user The address of the borrower getting liquidated
     * @param debtToCover The debt amount of borrowed `asset` the liquidator wants to cover
     * @param liquidatedCollateralAmount The amount of collateral received by the liiquidator
     * @param liquidator The address of the liquidator
     * @param receiveAToken `true` if the liquidators wants to receive the collateral aTokens, `false` if he wants
     * to receive the underlying collateral asset directly
     *
     */
    event LiquidationCall(
        address indexed collateralAsset,
        address indexed debtAsset,
        address indexed user,
        uint256 debtToCover,
        uint256 liquidatedCollateralAmount,
        address liquidator,
        bool receiveAToken
    );

    event FlashLoan(
        address receiverAddress,
        address sender,
        address[] assets,
        uint256[] currentAmount,
        uint256[] currentPremium,
        uint16 referralCode
    );

    constructor(address _daiToken, address _wethToken, address[] memory _aToken, address[] memory _debtToken) public {
        daiToken = MockERC20(_daiToken);
        wethToken = MockERC20(_wethToken);
        aToken[_daiToken] = _aToken[0];
        aToken[_wethToken] = _aToken[1];
        debtToken[_daiToken] = _debtToken[0];
        debtToken[_wethToken] = _debtToken[1];
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 userBalance = MockERC20(aToken[asset]).balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount > userBalance) {
            amountToWithdraw = userBalance;
        }

        MockERC20(aToken[asset]).burn(to, amountToWithdraw);

        MockERC20(asset).transfer(to, amountToWithdraw);

        emit Withdraw(asset, to, to, amountToWithdraw);

        return amountToWithdraw;
    }

    function borrow(address asset, uint256 amount, address onBehalfOf) external {
        MockERC20(asset).transfer(onBehalfOf, amount);

        MockERC20(debtToken[asset]).mint(onBehalfOf, amount);

        emit Borrow(asset, msg.sender, onBehalfOf, amount);
    }

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        MockERC20(asset).transferFrom(onBehalfOf, address(this), amount);

        MockERC20(aToken[asset]).mint(onBehalfOf, amount);

        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }

    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256) {
        require(amount <= MockERC20(debtToken[asset]).balanceOf(onBehalfOf), "amount > debtTokenBalance");

        MockERC20(asset).transferFrom(onBehalfOf, address(this), amount);

        MockERC20(debtToken[asset]).burn(onBehalfOf, amount);

        emit Repay(asset, onBehalfOf, msg.sender, amount);

        return amount;
    }

    function flashLoan(
        address receiverAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address onBehalfOf,
        bytes calldata params,
        uint16 referralCode
    ) external {
        uint256 borrowAmounts = amounts[0];

        uint256[] memory _premiums = new uint256[](1);
        if (modes[0] == 0) {
            _premiums[0] = (borrowAmounts * 9) / 10000;
            borrowAmounts = (borrowAmounts * 10009) / 10000;
        }
        MockERC20(assets[0]).transfer(onBehalfOf, amounts[0]);

        IFlashLoanReceiver(msg.sender).executeOperation(assets, amounts, _premiums, msg.sender, params);

        if (modes[0] == 0) {
            MockERC20(assets[0]).transferFrom(onBehalfOf, address(this), borrowAmounts);
        } else {
            MockERC20(debtToken[assets[0]]).mint(onBehalfOf, borrowAmounts);
        }

        emit FlashLoan(receiverAddress, msg.sender, assets, amounts, _premiums, referralCode);
    }

    function liquidationCall(
        address collateral,
        address debt,
        address user,
        uint256 debtToCover,
        bool receiveAToken
    ) public {
        uint256 debtAmount = MockERC20(debt).balanceOf(user);
        require(debtToCover <= debtAmount / 2, "liquidation debtAmount too more");
        //简单粗暴直接 1：1
        address borrowToken;
        address depositToken;
        if (debtToken[address(daiToken)] == debt) {
            borrowToken = address(daiToken);
            depositToken = address(wethToken);
        } else {
            borrowToken = address(wethToken);
            depositToken = address(daiToken);
        }
        MockERC20(borrowToken).transferFrom(msg.sender, address(this), debtToCover);
        MockERC20(debt).burn(user, debtToCover);
        if (receiveAToken) {
            MockERC20(aToken[depositToken]).transferFrom(user, msg.sender, (debtToCover * 105) / 100);
        } else {
            MockERC20(depositToken).transfer(msg.sender, (debtToCover * 105) / 100);
            MockERC20(aToken[depositToken]).burn(user, (debtToCover * 105) / 100);
        }
        emit LiquidationCall(
            aToken[depositToken], debt, user, debtToCover, (debtToCover * 105) / 100, msg.sender, receiveAToken
            );
    }
}
