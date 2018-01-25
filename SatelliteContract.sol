pragma solidity ^0.4.10;

contract QRC20Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
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
    address[] public appAddressList;

    event Voted(uint8 indexed _turn, address indexed _voter, string _luckyNumber);
    event ResultSet(uint8 indexed _turn, string _randomSeed, string _luckyNumber);
    event Paid(uint8 indexed _turn, address indexed _voter, uint amount);

    modifier onlyApp() {
        bool contain = false;
        for (uint i=0; i < appAddressList.length; i++) {
            if (msg.sender == appAddressList[i]) {
                contain = true;
                break;
            }
        }
        require(contain);
        _;
    }

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
    function vote(address _voter, string _luckyNumber) public onlyApp
    returns (bool success) {
        voteRecord[currentTurn][_voter] = _luckyNumber;
        Voted(currentTurn, _voter, _luckyNumber);
        return true;
    }

    // 计算某一期的中奖结果
    function getRewardLevel(uint8 _turn, address _voter) public
    returns (uint8 level) {
        string result = resultOf(_turn);
        string record = voteRecord[_turn][_voter];

        // todo 得找个复杂度低的算法

    }

    // 设置结果
    function setResult(string _randomSeed) public onlyManager
    returns (bool success) {
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
        // todo 比对结果，计算奖金，发币--------坑
        uint8 level = getRewardLevel(_turn, _voter);

    }

    // 获取所有奖金
    function getAllReward(address _voter) public {
        for (uint8 i=1; i < currentTurn; i++) {
            getRewardOfTurn(_voter, i);
        }
    }

    // 提取所有剩余的qtum和其他币
    function withdraw() onlyManager {
        msg.sender.transfer(this.balance);
        QRC20Token[] tokens = [inkToken, chatToken, qbaoToken, spcToken];
        for (uint i=0; i < tokens.length; i++) {
            QRC20Token token = tokens[i];
            token.transfer(msg.sender, token.balanceOf(this)-1); // ink issue
        }
    }

    function addApp(address _app) public onlyManager {
        appAddressList.push(_app);
    }

    function removeApp(uint _index) public onlyManager {
        require(_index < appAddressList.length);
        for (uint i=0; i< appAddressList.length; i++) {
            if (i == appAddressList.length -1) {
                delete appAddressList[i];
                appAddressList.length -= 1;
            }
            else if (i >= _index) {
                appAddressList[i] = appAddressList[i+1];
            }
        }
    }


    // disable pay QTUM to this contract
    function () public payable {
        revert();
    }
}
