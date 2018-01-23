pragma solidity ^0.4.10;

contract QRC20Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract SatelliteContract {

    QRC20Token spcToken;
    QRC20Token chatToken;
    QRC20Token qbaoToken;
    QRC20Token inkToken;

    address contractManager; // 卫星
    uint8 public currentTurn; // 当前开奖轮次
    uint public lastBlockHeight; // 上一轮的开奖区块高度

    mapping(uint8 => mapping(address => string)) public voteRecord; // 用户投注记录
    mapping(uint8 => mapping(address => bool)) public paidRecord; // 用户领奖记录
    mapping(uint8 => string) public resultOf; // 随机数结果记录
    uint8 resultLength = 5;
    bytes table = "0123456789";

    event Vote(uint8 indexed _turn, address indexed _voter, string _luckyNumber);
    event ResultSet(uint8 indexed _turn, string _randomSeed, string _luckyNumber);
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
        currentTurn = 0;
    }

    // 投注
    function vote(address _voter, string _luckyNumber) public
    returns (bool) {
        voteRecord[currentTurn][_voter] = _luckyNumber;
        Vote(currentTurn, _voter, _luckyNumber);
        return true;
    }

    // 计算某一期的中奖结果
    function getRewardPercentage(uint8 _turn, address _voter) returns (uint8 _percentage) {
        string result = resultOf(_turn);
        string record = voteRecord[_turn][_voter];

        // todo

    }

    // 设置结果
    function setResult(string _randomSeed) public onlyManager
    returns (bool) {
        if (block.number - lastBlockHeight < 1000) {
            return false;
        }

        bytes32 blockhash = block.blockhash(block.number);
        uint256 hash = uint256(keccak256(blockhash, _randomSeed));
        bytes memory encode = new bytes(resultLength);
        for(uint8 i = 0; i < resultLength; i++) {
            uint256 rem = hash % 10;
            hash = hash / 10;
            encode[i] = table[rem];
        }
        string luckyNumber = new string(resultLength);
        luckyNumber = string(encode);

        resultOf[currentTurn] = luckyNumber;
        ResultSet(currentTurn, _randomSeed, luckyNumber);
        currentTurn += 1;
        return true;
    }

    // 获取某一期奖金
    function getRewardOfTurn(uint8 _turn, address _voter) public {
        if (paidRecord[_turn][_voter]) {
            return;
        }
        // todo 比对结果，计算奖金，发币---坑
        uint8 percentage = getRewardPercentage(_turn, _voter);

    }

    // 获取所有奖金
    function getAllReward(address _voter) public {
        for (uint8 i=1; i < currentTurn; i++) {
            getRewardOfTurn(_voter, i);
        }
    }

    // 提取所有剩余的qtum和其他币
    function withdraw() onlyManager {
        // todo ---坑
    }

    // disable pay QTUM to this contract
    function () public payable {
        revert();
    }

}
