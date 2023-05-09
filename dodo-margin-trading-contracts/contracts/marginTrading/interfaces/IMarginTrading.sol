// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

interface IMarginTrading {
    //---------------event-----------------
    event FlashLoans(address[] assets, uint256[] amounts, uint256[] modes, address mainToken);
    event OpenPosition(
        address indexed swapAddress, address[] swapApproveToken, address[] tradAssets, uint256[] tradAmounts
    );
    event ClosePosition(
        uint8 _flag,
        address indexed swapAddress,
        address[] swapApproveToken,
        address[] tradAssets,
        uint256[] tradAmounts,
        address[] withdrawAssets,
        uint256[] withdrawAmounts,
        uint256[] _rateMode,
        uint256[] _returnAmounts
    );

    event LendingPoolWithdraw(address indexed asset, uint256 indexed amount, uint8 _flag);

    event LendingPoolDeposit(address indexed asset, uint256 indexed amount, uint8 _flag);

    event LendingPoolRepay(address indexed asset, uint256 indexed amount, uint256 indexed rateMode, uint8 _flag);

    event WithdrawERC20(address indexed marginAddress, uint256 indexed marginAmount, bool indexed margin, uint8 _flag);

    event WithdrawETH(uint256 indexed marginAmount, bool indexed margin, uint8 _flag);

    //---------------view-----------------

    function user() external view returns (address _userAddress);

    function getContractAddress() external view returns (address _lendingPoolAddress, address _WETHAddress);

    //---------------function-----------------
    function multicall(bytes[] calldata data) external payable returns (bytes[] memory results);

    function executeFlashLoans(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external;

    function lendingPoolWithdraw(address _asset, uint256 _amount, uint8 _flag) external;

    function lendingPoolDeposit(address _asset, uint256 _amount, uint8 _flag) external;

    function lendingPoolRepay(address _repayAsset, uint256 _repayAmt, uint256 _rateMode, uint8 _flag) external;

    function withdrawERC20(address _marginAddress, uint256 _marginAmount, bool _margin, uint8 _flag) external;

    function withdrawETH(bool _margin, uint256 _marginAmount, uint8 _flag) external payable;

    function initialize(address _lendingPool, address _weth, address _user) external;
}
