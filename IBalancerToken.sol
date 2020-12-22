interface IBalancerToken {
    function balanceOf(address) external returns (uint);
    function allowance(address, address) external returns (uint);
    function approve(address, uint) external returns (bool);
    function transfer(address, uint) external returns (bool);
    function transferFrom(address, address, uint) external returns (bool);
    function deposit() external payable;
    function withdraw(uint) external;
}
