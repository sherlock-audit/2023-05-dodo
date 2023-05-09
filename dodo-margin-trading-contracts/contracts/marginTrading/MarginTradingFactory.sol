// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.15;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {IMarginTrading} from "./interfaces/IMarginTrading.sol";
import {IMarginTradingFactory} from "./interfaces/IMarginTradingFactory.sol";
import {IWETH} from "./interfaces/IWETH.sol";
import {IDODOApprove} from "./interfaces/IDODOApprove.sol";
import {MarginTrading} from "./MarginTrading.sol";

contract MarginTradingFactory is Ownable, IMarginTradingFactory {
    event CleanToken(address _tokenAddress, address _to, uint256 _amount);

    event CleanETH(address _to, uint256 _amount);

    address public immutable MARGIN_TRADING_TEMPLATE;
    address internal LendingPool;
    IWETH internal WETH;
    IDODOApprove internal DODOApprove;
    // user => approveAddress = > bool
    mapping(address => mapping(address => bool)) public ALLOWED_FLASH_LOAN;

    mapping(address => address[]) public crossMarginTrading;

    mapping(address => address[]) public isolatedMarginTrading;

    //user approve close address
    constructor(address _lendingPool, address _weth, address _DODOApprove, address _template) {
        LendingPool = _lendingPool;
        WETH = IWETH(_weth);
        MARGIN_TRADING_TEMPLATE = _template;
        DODOApprove = IDODOApprove(_DODOApprove);
    }

    receive() external payable {}

    /// @notice Get the marginTrading contract address created by the user.
    /// @param _num MarginTrading contract Num
    /// @param _flag 1 -cross , 2 - isolated
    /// @param _user User address
    /// @return _ad User marginTrading contract
    function getCreateMarginTradingAddress(
        uint256 _num,
        uint8 _flag,
        address _user
    ) external view returns (address _ad) {
        _ad =
            Clones.predictDeterministicAddress(MARGIN_TRADING_TEMPLATE, keccak256(abi.encodePacked(_user, _num, _flag)));
    }

    /// @notice To get the number of marginTrading contracts created by a user.
    /// @param _user User address
    /// @return _crossNum User cross marginTrading contract num
    /// @return _isolateNum User isolate marginTrading contract num
    function getUserMarginTradingNum(address _user) external view returns (uint256 _crossNum, uint256 _isolateNum) {
        _crossNum = crossMarginTrading[_user].length;
        _isolateNum = isolatedMarginTrading[_user].length;
    }

    /// @notice Get whether the proxyAddress is allowed to call the marginTrading contract.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy user address
    /// @return True is Allowed
    function isAllowedProxy(address _marginTradingAddress, address _proxy) external view returns (bool) {
        return ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy];
    }

    /// @notice Call multiple functions in the current contract and return the data from all of them if they all succeed
    /// @param data The encoded function data for each of the calls to make to this contract
    /// @return results The results from each of the calls passed in via data
    function multicall(bytes[] calldata data) public payable returns (bytes[] memory results) {
        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            if (!success) {
                assembly {
                    revert(add(result, 32), mload(result))
                }
            }

            results[i] = result;
        }
    }

    // ============ Functions ============

    /// @notice Add the proxy address that is allowed to execute flashloan operations.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy address
    function addFlashLoanProxy(address _marginTradingAddress, address _proxy) external {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "caller is not the user");
        ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy] = true;
    }

    /// @notice Delete the proxy address that is allowed to execute flash loan operation.
    /// @param _marginTradingAddress Margin trading address
    /// @param _proxy Proxy address
    function removeFlashLoanProxy(address _marginTradingAddress, address _proxy) external {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "caller is not the user");
        ALLOWED_FLASH_LOAN[_marginTradingAddress][_proxy] = false;
    }

    /// @notice Create a marginTrading contract for the user, deposit funds, and open a position.
    /// @dev 1.Create a marginTrading contract for the user.
    /// @dev 2.Make a deposit.
    /// @dev 3.Execute the executeFlashLoans method of the marginTrading contract to open a position.
    /// @param _flag 1 -cross , 2 - isolated
    /// @param depositParams Deposit execution parameters.
    /// @param executeParams The parameters for executing the executeFlashLoans function in the marginTrading contract.
    /// @return marginTrading Create marginTrading address
    function createMarginTrading(
        uint8 _flag,
        bytes calldata depositParams,
        bytes calldata executeParams
    ) external payable returns (address marginTrading) {
        if (_flag == 1) {
            marginTrading = Clones.cloneDeterministic(
                MARGIN_TRADING_TEMPLATE,
                keccak256(abi.encodePacked(msg.sender, crossMarginTrading[msg.sender].length, _flag))
            );
            crossMarginTrading[msg.sender].push(marginTrading);
            emit MarginTradingCreated(msg.sender, marginTrading, crossMarginTrading[msg.sender].length, _flag);
        }
        if (_flag == 2) {
            marginTrading = Clones.cloneDeterministic(
                MARGIN_TRADING_TEMPLATE,
                keccak256(abi.encodePacked(msg.sender, isolatedMarginTrading[msg.sender].length, _flag))
            );
            isolatedMarginTrading[msg.sender].push(marginTrading);
            emit MarginTradingCreated(msg.sender, marginTrading, isolatedMarginTrading[msg.sender].length, _flag);
        }
        //调用marginTrading地址的合约中的"initialize"方法,LendingPool,WETH,user
        IMarginTrading(marginTrading).initialize(LendingPool, address(WETH), msg.sender);
        if (depositParams.length > 0) {
            (
                uint8 _depositFlag, //1- erc20 2-eth
                address _tokenAddres,
                uint256 _depositAmount
            ) = abi.decode(depositParams, (uint8, address, uint256));
            if (_depositFlag == 1) {
                _depositMarginTradingERC20(marginTrading, _tokenAddres, _depositAmount, false, uint8(1));
            }
            if (_depositFlag == 2) {
                depositMarginTradingETH(marginTrading, false, uint8(1));
            }
        }
        if (executeParams.length > 0) {
            (
                address[] memory _assets,
                uint256[] memory _amounts,
                uint256[] memory _modes,
                address _mainToken,
                bytes memory _params
            ) = abi.decode(executeParams, (address[], uint256[], uint256[], address, bytes));
            _executeMarginTradingFlashLoans(marginTrading, _assets, _amounts, _modes, _mainToken, _params);
        }
    }

    /// @notice Execution marginTrading executeFlashLoans methods for opening and closing.
    /// @dev Execute a flash loan and pass the parameters to the executeOperation method.
    /// @param assets Borrowing assets
    /// @param amounts Borrowing assets amounts
    /// @param modes Borrowing assets premiums
    /// @param mainToken initiator address
    /// @param params The parameters for the execution logic.
    function executeMarginTradingFlashLoans(
        address _marginTradingAddress,
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata modes,
        address mainToken,
        bytes calldata params
    ) external {
        _executeMarginTradingFlashLoans(_marginTradingAddress, assets, amounts, modes, mainToken, params);
    }

    /// @notice User deposits ERC20 token into marginTrading contract.
    /// @dev Use DODOApprove to allow users to deposit ERC20 tokens into the marginTrading contract.
    /// @param _marginTradingAddress User marginTrading contract address
    /// @param _marginAddress Margin token address
    /// @param _marginAmount Margin token amount
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function depositMarginTradingERC20(
        address _marginTradingAddress,
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) external {
        _depositMarginTradingERC20(_marginTradingAddress, _marginAddress, _marginAmount, _margin, _flag);
    }

    /// @notice User deposits ETH into marginTrading contract.
    /// @dev Convert ETH to ERC20 token using the WETH contract, and then deposit it into the marginTrading contract.
    /// @param _marginTradingAddress User marginTrading contract address
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function depositMarginTradingETH(address _marginTradingAddress, bool _margin, uint8 _flag) public payable {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory:caller is not the user");
        WETH.deposit{value: msg.value}();
        WETH.transfer(_marginTradingAddress, msg.value);
        if (_margin) {
            IMarginTrading(_marginTradingAddress).lendingPoolDeposit(address(WETH), msg.value, _flag);
        }
        emit DepositMarginTradingETH(_marginTradingAddress, msg.value, _margin, _flag);
    }

    /// @notice Owner clean contract ERC20 token
    /// @param _tokenAddress send ERC20 token address
    /// @param _to To address
    /// @param _amt send ERC20 token amount
    function cleanToken(address _tokenAddress, address _to, uint256 _amt) external onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amt);
        emit CleanToken(_tokenAddress, _to, _amt);
    }

    /// @notice Owner clean contract ETH.
    /// @param _to To address
    /// @param _amt send ETH amount
    function cleanETH(address _to, uint256 _amt) external onlyOwner {
        (bool success,) = _to.call{value: _amt}(new bytes(0));
        require(success, "ETH_TRANSFER_FAILED");
        emit CleanETH(_to, _amt);
    }

    // =========== internal ==========

    /// @notice Execution marginTrading contract methods for opening and closing.
    /// @dev Execute a flash loan and pass the parameters to the executeOperation method.
    /// @param _marginTradingAddress MarginTrading contract address
    /// @param assets Borrowing assets
    /// @param amounts Borrowing assets amounts
    /// @param modes Borrowing assets premiums
    /// @param mainToken initiator address
    /// @param params The parameters for the execution logic.
    function _executeMarginTradingFlashLoans(
        address _marginTradingAddress,
        address[] memory assets,
        uint256[] memory amounts,
        uint256[] memory modes,
        address mainToken,
        bytes memory params
    ) internal {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory: caller is not the user");
        IMarginTrading(_marginTradingAddress).executeFlashLoans(assets, amounts, modes, mainToken, params);
    }

    /// @notice Deposits ERC20 token into marginTrading contract.
    /// @param _marginTradingAddress MarginTrading contract address
    /// @param _marginAddress margin token address
    /// @param _marginAmount margin token Amount
    /// @param _margin Whether to be used as collateral
    /// @param _flag Operation flag
    function _depositMarginTradingERC20(
        address _marginTradingAddress,
        address _marginAddress,
        uint256 _marginAmount,
        bool _margin,
        uint8 _flag
    ) internal {
        require(IMarginTrading(_marginTradingAddress).user() == msg.sender, "factory:caller is not the user");
        DODOApprove.claimTokens(_marginAddress, msg.sender, _marginTradingAddress, _marginAmount);
        if (_margin) {
            IMarginTrading(_marginTradingAddress).lendingPoolDeposit(_marginAddress, _marginAmount, _flag);
        }
        emit DepositMarginTradingERC20(_marginTradingAddress, _marginAddress, _marginAmount, _margin, _flag);
    }
}
