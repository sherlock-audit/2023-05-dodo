import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { GOERLI_CONFIG as config } from "../../config/eth-config";
process.env.HTTPS_PROXY = 'http://127.0.0.1:7890';
process.env.HTTP_PROXY = 'http://127.0.0.1:7890'; // 为 non-SSL request做代理
const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts , ethers} = hre; //
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deployMarginTradingFactory();
  // await deployMarginTradingFactoryMock();

  async function deployContract(name: string, contract: string, args: any[]) {
    if (!config.deployedAddress[name] || config.deployedAddress[name] == "") {
      const deployResult = await deploy(contract, {
        from: deployer,
        args: args,
        log: true,
      });
      return deployResult.address;
    } else {
      return config.deployedAddress[name];
    }
  }

  async function verifyContract(address: string, args?: any[]) {
    await sleep(15);
    if (typeof args == 'undefined') {
      args = []
    }
    try {
      await hre.run("verify:verify", {
        address: address,
        constructorArguments: args,
      });
    } catch (e) {
      if (e.message != "Contract source code already verified") {
        throw(e)
      }
      console.log(e.message)
    }
  }

  async function deployMarginTradingFactory() {
    //先部署 MarginTrading
    const marginTradingTemplates = await deployContract("MarginTradingTemplates", "MarginTrading", []);
    await verifyContract(marginTradingTemplates, [])
    //然后部署 MarginTradingFactory
    const marginTradingFactory = await deployContract("MarginTradingFactory", "MarginTradingFactory", [config.deployedAddress.lendingPool,config.deployedAddress.wethAddress,config.deployedAddress.DODOApproveProxy,marginTradingTemplates]);
    await verifyContract(marginTradingFactory, [config.deployedAddress.lendingPool,config.deployedAddress.wethAddress,config.deployedAddress.DODOApproveProxy,marginTradingTemplates])
    //最后给 MarginTradingFactory 授权 人工授权【无统一权限】
    // const approveProxy = await ethers.getContractAt("DODOApproveProxy", config.deployedAddress.DODOApproveProxy);
    // await approveProxy.unlockAddProxy(marginTradingFactory);
    // await sleep(15);
    // await approveProxy.addDODOProxy();
  }


  async function deployMarginTradingFactoryMock() {
    //部署mockToken
    const daiAddress = "0x2D9FAAe7C458316434804EdEe566b80BaDe540F6";
    // const daiAddress = await deployContract("daiAddress", "MockERC20", ["Dai Stablecoin", "DAI", 18]); //0x2D9FAAe7C458316434804EdEe566b80BaDe540F6
    // await verifyContract(daiAddress, ["Dai Stablecoin", "DAI", 18]);

    const daiAAddress = "0x9aD48E24618ef946e5A0f01646b60963115FC853";
    // const daiAAddress = await deployContract("daiAAddress", "MockAaveERC20", ["Dai A Token", "DAIAToken", 18]);//0x9aD48E24618ef946e5A0f01646b60963115FC853
    // await verifyContract(daiAAddress, ["Dai A Token", "DAIAToken", 18]);

    const daiDebtAddress = "0xa8b8eae4457FC84390F78c86e7B3997802BA1ee3";
    // const daiDebtAddress = await deployContract("daiDebtAddress", "MockAaveERC20", ["Dai Debt Token", "DAIDebtToken", 18]); //0xa8b8eae4457FC84390F78c86e7B3997802BA1ee3
    // await verifyContract(daiDebtAddress, ["Dai Debt Token", "DAIDebtToken", 18]);

    const wethAddress = "0x08E3AA877756BFcaDf981d7753f02B804a342d24";
    // const wethAddress = await deployContract("wethAddress", "WETH9", []); //0x08E3AA877756BFcaDf981d7753f02B804a342d24
    // await verifyContract(wethAddress, []);

    const wethAAddress = "0x42fb31E710b94a0478D712B440fd6891Af194Ffc";
    // const wethAAddress = await deployContract("wethAAddress", "MockAaveERC20", ["Weth A Token", "WethAToken", 18]); //0x42fb31E710b94a0478D712B440fd6891Af194Ffc
    // await verifyContract(wethAAddress, ["Weth A Token", "WethAToken", 18]);

    const wethDebtAddress = "0x5A9BC685359dfbeB61e68Cb7e36D2e7F4828DabF";
    // const wethDebtAddress = await deployContract("wethDebtAddress", "MockAaveERC20", ["Weth Debt Token", "WethDebtToken", 18]);//0x5A9BC685359dfbeB61e68Cb7e36D2e7F4828DabF
    // await verifyContract(wethDebtAddress,  ["Weth Debt Token", "WethDebtToken", 18]);

    // //部署Approve
    const DODOApproveAddress = "0xFc20740b2Bf4e0071105498f5850AA3B70f221FD";
    // const DODOApproveAddress = await deployContract("DODOApproveAddress", "DODOApprove", []); //0xFc20740b2Bf4e0071105498f5850AA3B70f221FD
    // await verifyContract(DODOApproveAddress, []);

    //部署ApprovePoxy
    const DODOApproveProxyAddress = "0xA8A6C7aD71B6e04ee653749869E36B7f3C0ab6B6";
    // const DODOApproveProxyAddress = await deployContract("DODOApproveProxyAddress", "DODOApproveProxy", [DODOApproveAddress]);//0xA8A6C7aD71B6e04ee653749869E36B7f3C0ab6B6
    // await verifyContract(DODOApproveProxyAddress, [DODOApproveAddress]);
    // await DODOApproveAddress.init(config.deployedAddress.User,DODOApproveProxyAddress);
    // const approveProxyContract = await ethers.getContractAt("DODOApprove", DODOApproveAddress);
    // await approveProxyContract.init(config.deployedAddress.User,DODOApproveProxyAddress);;


    //部署mockRoute
    const RouterAddress = "0x764e7140c62E91ED8445A5ae18B0D73a0E46E461";
    // const RouterAddress = await deployContract("RouterAddress", "MockRouter", [DODOApproveProxyAddress]); //0x764e7140c62E91ED8445A5ae18B0D73a0E46E461
    // await verifyContract(RouterAddress,  [DODOApproveProxyAddress]);

    //部署mockLendingPool
    const lendingPoolV2tAddress = "0xfBc3EFce7A9e190E050B53F4D0a1131dbC339cc2";
    // const lendingPoolV2tAddress = await deployContract("lendingPoolV2tAddress", "MockLendingPoolV2", [daiAddress,wethAddress, [daiAAddress,wethAAddress],[daiDebtAddress,wethDebtAddress]]);
    //0xe6F764443bb2ee6d5980fF64F0E7e82AA02Cc830
    await verifyContract(lendingPoolV2tAddress,  [daiAddress,wethAddress, [daiAAddress,wethAAddress],[daiDebtAddress,wethDebtAddress]]);

    //然后部署 MarginTradingFactory
    const marginTradingFactory = await deployContract("MarginTradingFactory", "MarginTradingFactory", [lendingPoolV2tAddress,wethAddress,DODOApproveProxyAddress,config.deployedAddress.MarginTradingTemplates]);
    //0x404a8c32ed15eb9d556fcb22ec716b1837c9bc93
    await verifyContract(marginTradingFactory, [lendingPoolV2tAddress,wethAddress,DODOApproveProxyAddress,config.deployedAddress.MarginTradingTemplates]);
    
    // const DODOApproveProxyContract = await ethers.getContractAt("DODOApproveProxy", DODOApproveProxyAddress);
    // await DODOApproveProxyContract.init(config.deployedAddress.User,[marginTradingFactory,RouterAddress,lendingPoolV2tAddress]);;
  }

  


  // ---------- helper function ----------

  function sleep(s) {
    return new Promise(resolve => setTimeout(resolve, s * 1000));
  }
};

export default func;
