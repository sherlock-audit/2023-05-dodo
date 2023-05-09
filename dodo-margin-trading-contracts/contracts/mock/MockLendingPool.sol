// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import {IFlashLoanReceiver} from "../aaveLib/Interfaces.sol";

contract MockLendingPool {
    MockERC20 public depositToken; //存入token
    MockERC20 public borrowToken; //借贷token

    MockERC20 public aToken; //标记存款
    MockERC20 public debtToken; //标记借款

    event Withdraw(address asset, address user, address to, uint256 amountToWithdraw);

    event Deposit(address asset, address sender, address onBehalfOf, uint256 amount, uint16 referralCode);

    event Borrow(address asset, address sender, address onBehalfOf, uint256 amount);

    event Repay(address asset, address onBehalfOf, address user, uint256 amount);

    event FlashLoan(
        address receiverAddress,
        address sender,
        address[] assets,
        uint256[] currentAmount,
        uint256[] currentPremium,
        uint16 referralCode
    );

    constructor(MockERC20 _deposit, MockERC20 _borrow, MockERC20 _aToken, MockERC20 _debtToken) public {
        depositToken = _deposit;
        borrowToken = _borrow;
        aToken = _aToken;
        debtToken = _debtToken;
    }

    function setToken(MockERC20 _depositToken, MockERC20 _borrowToken) public {
        depositToken = _depositToken;
        borrowToken = _borrowToken;
    }

    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 userBalance = aToken.balanceOf(msg.sender);

        uint256 amountToWithdraw = amount;

        if (amount > userBalance) {
            amountToWithdraw = userBalance;
        }

        aToken.burn(to, amountToWithdraw);

        depositToken.transfer(to, amount);

        emit Withdraw(asset, to, to, amountToWithdraw);

        return amountToWithdraw;
    }

    function borrow(address asset, uint256 amount, address onBehalfOf) external {
        borrowToken.transfer(onBehalfOf, amount);

        debtToken.mint(onBehalfOf, amount);

        emit Borrow(asset, msg.sender, onBehalfOf, amount);
    }

    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external {
        depositToken.transferFrom(onBehalfOf, address(this), amount);

        aToken.mint(onBehalfOf, amount);

        emit Deposit(asset, msg.sender, onBehalfOf, amount, referralCode);
    }

    function repay(address asset, uint256 amount, uint256 rateMode, address onBehalfOf) external returns (uint256) {
        require(amount <= debtToken.balanceOf(onBehalfOf), "amount > debtTokenBalance");

        borrowToken.transferFrom(onBehalfOf, address(this), amount);

        debtToken.burn(onBehalfOf, amount);

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
        borrowToken.transfer(onBehalfOf, borrowAmounts);

        IFlashLoanReceiver(msg.sender).executeOperation(assets, amounts, _premiums, msg.sender, params);

        if (modes[0] == 0) {
            borrowToken.transferFrom(onBehalfOf, address(this), borrowAmounts);
        } else {
            debtToken.mint(onBehalfOf, borrowAmounts);
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
        uint256 debtAmount = debtToken.balanceOf(user);
        require(debtToCover <= debtAmount / 2, "liquidation debtAmount too more");
        borrowToken.transferFrom(msg.sender, address(this), debtToCover);
        debtToken.burn(user, debtToCover);
        if (receiveAToken) {
            aToken.transferFrom(user, msg.sender, (debtToCover * 105) / 100);
        } else {
            depositToken.transfer(msg.sender, (debtToCover * 105) / 100);
            aToken.burn(user, (debtToCover * 105) / 100);
        }
    }
}
