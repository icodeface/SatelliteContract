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
    uint qtumBaseAwardAmount;
    uint spcBaseAwardAmount;
    uint chatBaseAwardAmount;
    uint qbaoBaseAwardAmount;
    uint inkBaseAwardAmount;

    address contractManager; // 卫星
    uint8 public currentTurn; // 当前开奖轮次
    uint public lastBlockHeight; // 上一轮的开奖区块高度
    uint public voteGap = 1000;
    uint8 resultLength = 7;
    bytes table = "0123456789";

    mapping(uint8 => mapping(address => string)) public voteRecord; // 用户投注记录
    mapping(uint8 => mapping(address => bool)) public paidRecord; // 用户领奖记录
    mapping(uint8 => string) public resultOf; // 随机数结果记录
    mapping(uint8 => uint) countRecord; // 每轮投注总人数
    address[] public appAddressList;

    event Voted(uint8 indexed _turn, address indexed _voter, string _luckyNumber);
    event ResultSet(uint8 indexed _turn, string _randomSeed, string _luckyNumber);
    event Paid(uint8 indexed _turn, address indexed _voter);

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
        lastBlockHeight = 55000;
        currentTurn = 0;

        // todo
        spcToken    = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        chatToken   = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        qbaoToken   = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        inkToken    = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);

        qtumBaseAwardAmount    = 1*10**8;
        spcBaseAwardAmount     = 1*10**8;
        chatBaseAwardAmount    = 1*10**8;
        qbaoBaseAwardAmount    = 1*10**8;
        inkBaseAwardAmount     = 1*10**9;

    }

    // 投注
    function vote(address _voter, string _luckyNumber) public onlyApp
    returns (bool success) {
        assert(_luckyNumber.length == resultLength);
        voteRecord[currentTurn][_voter] = _luckyNumber;
        countRecord[currentTurn] += 1;
        Voted(currentTurn, _voter, _luckyNumber);
        return true;
    }

    // 计算某一期的匹配个数
    function getMatchCount(uint8 _turn, address _voter) public
    returns (uint8 matchCount) {
        string result = resultOf(_turn);
        string record = voteRecord[_turn][_voter];
        matchCount = 0;
        for (uint8 i=0; i< resultLength; i++) {
            if (result[i] == record[i]) {
                matchCount += 1;
            }
        }
        return matchCount;
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
    function getAwardOfTurn(uint8 _turn, address _voter) public {
        if (paidRecord[_turn][_voter]) {
            return;
        }

        uint8 matchCount = getMatchCount(_turn, _voter);
        if (matchCount < resultLength - 3) {
            paidRecord[_turn][_voter] = true;
            return;
        }

        uint totalCount = countRecord[_turn];
        uint qtumAmount = (10**(3+matchCount-resultLength) * qtumBaseAwardAmount * 10**4) / totalCount;
        paidRecord[_turn][_voter] = true;
        _voter.transfer(qtumAmount);

        uint[] tokenBaseAmounts = [inkBaseAwardAmount, chatBaseAwardAmount, qbaoToken, spcBaseAwardAmount];
        QRC20Token[] tokens = [inkToken, chatToken, qbaoToken, spcToken];
        for (uint i=0; i < tokens.length; i++) {
            uint tokenAmount = (10**(3+matchCount-resultLength) * tokenBaseAmounts[i] * 10**4) / totalCount;
            QRC20Token token = tokens[i];
            token.transfer(_voter, tokenAmount);
        }
        Paid(_turn, _voter);
    }

    // 获取所有奖金
    function getAllAward(address _voter) public {
        for (uint8 i=1; i < currentTurn; i++) {
            getAwardOfTurn(_voter, i);
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
