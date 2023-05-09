// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./MockERC20.sol";
import "./DODOApproveProxy.sol";

contract MockRouter {
    DODOApproveProxy public dodoApproveProxy;

    constructor(DODOApproveProxy _dodoApproveProxy) {
        dodoApproveProxy = _dodoApproveProxy;
    }

    function swap(address fromToken, address toToken, uint256 fromAmount) public {
        uint256 fromTokenBalance = MockERC20(fromToken).balanceOf(address(this));
        uint256 toTokenBalance = MockERC20(toToken).balanceOf(address(this));
        uint256 toAmount = toTokenBalance - (toTokenBalance * fromTokenBalance) / (fromTokenBalance + fromAmount);
        dodoApproveProxy.claimTokens(fromToken, msg.sender, address(this), fromAmount);
        MockERC20(toToken).transfer(msg.sender, toAmount);
    }

    function swapError() public {
        require(false, "swapError");
    }

    function encodeFlashLoan(
        address[] memory _assets,
        uint256[] memory _amounts,
        uint256[] memory _modes,
        address _mainToken,
        bytes memory _params
    ) public pure returns (bytes memory result) {
        result = abi.encode(_assets, _amounts, _modes, _mainToken, _params);
    }

    function encodeExecuteParams(
        uint8 _flag,
        address _swapAddress,
        address _swapApproveTarget,
        address[] memory _swapApproveToken,
        bytes memory _swapParams,
        address[] memory _tradeAssets,
        address[] memory _withdrawAssets,
        uint256[] memory _withdrawAmounts,
        uint256[] memory _rateMode,
        address[] memory _debtTokens
    ) public pure returns (bytes memory result) {
        result = abi.encode(
            _flag,
            _swapAddress,
            _swapApproveTarget,
            _swapApproveToken,
            _swapParams,
            _tradeAssets,
            _withdrawAssets,
            _withdrawAmounts,
            _rateMode,
            _debtTokens
        );
    }

    function encodeDepositParams(
        uint8 _depositFlag, //1- erc20 2-eth
        address _tokenAddres,
        uint256 _depositAmount
    ) public pure returns (bytes memory result) {
        result = abi.encode(_depositFlag, _tokenAddres, _depositAmount);
    }

    function getSwapCalldata(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) public pure returns (bytes memory swapParams) {
        swapParams = abi.encodeWithSignature("swap(address,address,uint256)", fromToken, toToken, fromAmount);
    }

    function getRouterToAmount(
        address fromToken,
        address toToken,
        uint256 fromAmount
    ) public view returns (uint256 toAmount) {
        uint256 fromTokenBalance = MockERC20(fromToken).balanceOf(address(this));
        uint256 toTokenBalance = MockERC20(toToken).balanceOf(address(this));
        toAmount = toTokenBalance - (toTokenBalance * fromTokenBalance) / (fromTokenBalance + fromAmount);
    }
}
