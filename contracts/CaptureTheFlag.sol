pragma solidity ^0.4.12;

contract Log {
  struct Message {
    address Sender;
    string Data;
    uint Time;
  }

  Message[] public History;

  Message LastMsg;

  function addMessage(string memory _data) public {
    LastMsg.Sender = msg.sender;
    LastMsg.Time = now;
    LastMsg.Data = _data;
    History.push(LastMsg);
  }
}

contract Ownable {
  address public owner;
  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner){
      revert();
    }
    _;
  }

  modifier protected() {
      if(msg.sender != address(this)){
        revert();
      }
      _;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    if (newOwner == address(0)) {
      revert();
    }
    owner = newOwner;
  }

  function withdraw() public onlyOwner {
    msg.sender.transfer(address(this).balance);
  }
}

contract CaptureTheFlag is Ownable {
  address owner; // BUG: hide the owner variable from the base class
  event WhereAmI(address, string);
  Log TransferLog;
  uint256 public jackpot = 0;
  uint256 MinDeposit = 1 ether;
  uint256 minInvestment = 1 ether;
  uint public sumInvested; // posible underflow? not important
  uint public sumDividend; // not used
  bool inProgress = false;

  mapping(address => uint256) public balances;
  struct Osakako { // hum....
    address me;
  }
  struct investor { //blabla
    uint256 investment;
    string username;
  }
  event Transfer(
    uint amount,
    bytes32 message,
    address target,
    address currentOwner
  );

  mapping(address => investor) public investors;

  function CaptureTheFlag(address _log) public {
    TransferLog = Log(_log);
    owner = msg.sender;
  }

  function getOwner() public returns (address) {
    return owner;
  }

  // Payday!!
  function() public payable { // Steal your money
    if( msg.value >= jackpot ){
      owner = msg.sender; // don't change the real owner inherit from Ownable contract.
    }
    jackpot += msg.value; // gimme money !!
  }

  modifier onlyUsers() {
    require(users[msg.sender] != false);
    _;
  }

  mapping(address => bool) users;

  function registerAllPlayers(address[] players) public onlyOwner {
    require(inProgress == false);

    for (uint32 i = 0; i < players.length; i++) {
      users[players[i]] = true;
    }
    inProgress = true;
  }

  function takeAll() external onlyOwner {
    msg.sender.transfer(this.balance); // payout
    jackpot = 0; // reset the jackpot
  }
  // Payday!!

  // Bank
  function Deposit() public payable {
    if ( msg.value >= MinDeposit ){
      balances[msg.sender] += msg.value;
      TransferLog.addMessage(" Deposit ");
    }
  }

  function CashOut(uint amount) public onlyUsers {
    if( amount <= balances[msg.sender] ){
      if(msg.sender.call.value(amount)()){ // maybe...but..
        balances[msg.sender] -= amount;
        TransferLog.addMessage(" CashOut ");
      }
    }
  }
  // Bank

  //--- Hmmm
  function invest() public payable {
    if ( msg.value >= minInvestment ){
      investors[msg.sender].investment += msg.value;
    }
  }

  function divest(uint amount) public onlyUsers {
    if ( investors[msg.sender].investment == 0 || amount == 0) {
      revert();
    }
    // no need to test, this will throw if amount > investment
    investors[msg.sender].investment -= amount; //if invest is possible to underflow, but for what? there is no sufficient balance anyway....
    sumInvested -= amount;
    this.loggedTransfer(amount, "", msg.sender, owner);
  }

  function loggedTransfer(uint amount, bytes32 message, address target, address currentOwner) public protected onlyUsers {
    if(!target.call.value(amount)()){
      revert();
    }

    Transfer(amount, message, target, currentOwner);
  }
  //--- Empty String Literal

  // Solution2) Osakako osa;
  function osaka(string message) public onlyUsers {
    // Solution1) Osakako memory osakako;
    // Solution2) Osakako osakako =  osa;
    Osakako osakako; // pointer to storage location at Ownable (owner) 
    // https://github.com/ethereum/solidity/pull/4415/files#diff-48ec411cc833113f92ef1dc16d32d777L327
    osakako.me = msg.sender; // pwned
    WhereAmI(osakako.me, message);
  }

  function tryMeLast() public payable onlyUsers { //blabla
    if ( msg.value >= 0.1 ether ) {
      uint256 multi = 0;
      uint256 amountToTransfer = 0;
      for (var i = 0; i < 2 * msg.value; i++) {
        multi = i * 2;
        if (multi < amountToTransfer) {
          break;
        }
        amountToTransfer = multi;
      }
      msg.sender.transfer(amountToTransfer);
    }
  }

  function easyMode( address addr ) external payable onlyUsers {
    if ( msg.value >= this.balance ){
      addr.transfer(this.balance + msg.value);
    }
  }
}
