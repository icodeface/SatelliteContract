pragma solidity ^0.4.10;

contract QRC20Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract SatelliteContract {

    QRC20Token spcToken;
    QRC20Token chatToken;
    QRC20Token qbaoToken;

    address contractManager; // 卫星
    uint8 public currentTurn; // 当前开奖轮次
    uint public lastBlockHeight; // 上一轮的开奖区块高度

    mapping(uint8 => mapping(address => string)) public voteRecord; // 用户投注记录
    mapping(uint8 => mapping(address => bool)) public paidRecord; // 用户领奖记录
    mapping(uint8 => string) public resultOf; // 随机数结果记录

    event Vote(uint8 indexed _turn, address indexed _voter, string _luckyNumber);
    event ResultSet(uint8 indexed _turn, string _luckyNumber);
    event Paid(uint8 indexed _turn, address indexed _voter, uint amount);

    modifier onlyManager() {
        require(msg.sender == contractManager);
        _;
    }


    function SatelliteContract() {
        contractManager = msg.sender;
        // todo
        spcToken    = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        chatToken   = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        qbaoToken   = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        inkToken    = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        lastBlockHeight = 55000;
    }


    function vote(address _voter, string _luckyNumber) public
    returns (bool) {
        voteRecord[currentTurn][_voter] = _luckyNumber;
        Vote(currentTurn, _voter, _luckyNumber);
        return true;
    }

    function setResult(bytes32 _randomSeed) public onlyManager
    returns (bool) {
        if (block.number - lastBlockHeight < 1000) {
            return false;
        }

        bytes32 blockhash = block.blockhash(block.number);

        // todo 计算随机数结果


        resultOf[currentTurn] = _luckyNumber;
        ResultSet(currentTurn, _luckyNumber);
        currentTurn += 1;
        return true;
    }

    function getRewardOfTurn(uint8 _turn, address _voter) public {
        if (paidRecord[_turn][_voter]) {
            return;
        }
        // todo
    }

    function getAllReward(address _voter) public {
        for (uint8 i=0; i < currentTurn; i++) {
            getRewardOfTurn(_voter, i);
        }
    }

    // disable pay QTUM to this contract
    function () public payable {
        revert();
    }

}
