pragma solidity ^0.4.19;

contract QRC20Token {
    function transfer(address _to, uint256 _value) public returns (bool success);
    function balanceOf(address _owner) public constant returns (uint256 balance);
}

contract SatelliteContract {

    uint qtumBaseAward; //参与人数为1万的情况下三等奖的qtum奖金

    QRC20Token[] qrc20tokenList;
    uint[] tokenBaseAwardList; //参与人数为1万的情况下三等奖的各token奖金

    address contractManager; // 卫星
    uint8 public currentTurn; // 当前开奖轮次
    uint public lastBlockHeight; // 上一轮的开奖区块高度
    uint public voteGap = 2;
    uint8 resultLength = 5;
    bytes table = "0123456789";

    mapping(uint8 => mapping(address => string)) public voteRecord; // 用户投注记录
    mapping(uint8 => mapping(address => bool)) public paidRecord; // 用户领奖记录
    mapping(uint8 => string) public resultOf; // 随机数结果记录
    mapping(uint8 => uint) public countRecord; // 每轮投注总人数
    address[] public appAddressList; //beechat和qbao的地址

    event Voted(uint8 indexed _turn, address indexed _voter, string _luckyNumber);
    event ResultSet(uint8 indexed _turn, string _randomSeed, string _luckyNumber);
    event Paid(uint8 indexed _turn, address indexed _voter);

    modifier onlyApp() {
        // bool contain = false;
        // for (uint i=0; i < appAddressList.length; i++) {
        //     if (msg.sender == appAddressList[i]) {
        //         contain = true;
        //         break;
        //     }
        // }
        // require(contain);
        _;
    }

    modifier onlyManager() {
        require(msg.sender == contractManager);
        _;
    }


    function SatelliteContract() public {
        contractManager = msg.sender;
        lastBlockHeight = 0;
        currentTurn = 0;
        qtumBaseAward    = 1*10**8;

        QRC20Token qtcToken    = QRC20Token(0x06fffcfdc386f46fb94b78d9decb04649cef64c0);
        QRC20Token qbaoToken   = QRC20Token(0xe21bc819674c8f7cc7d76b618914ecff082107b3);
        QRC20Token inkToken    = QRC20Token(0xf19cabc74404cb772a8063a7294ab05f82b9b98f);

        qrc20tokenList.push(qtcToken);
        tokenBaseAwardList.push(1*10**8);

        qrc20tokenList.push(qbaoToken);
        tokenBaseAwardList.push(3*10**8);

        qrc20tokenList.push(inkToken);
        tokenBaseAwardList.push(5*10**9);
    }

    // 投注
    function vote(address _voter, string _luckyNumber) public onlyApp
    returns (bool success) {
        assert(bytes(_luckyNumber).length == uint(resultLength));
        voteRecord[currentTurn][_voter] = _luckyNumber;
        countRecord[currentTurn] += 1;
        Voted(currentTurn, _voter, _luckyNumber);
        return true;
    }

    // 计算某一期 某用户的中奖匹配个数
    function getMatchCount(uint8 _turn, address _voter) public view
    returns (uint8 matchCount)
    {
        string storage result = resultOf[_turn];
        string storage record = voteRecord[_turn][_voter];
        matchCount = 0;
        for (uint8 i=0; i< resultLength; i++) {
            if (bytes(result)[i] == bytes(record)[i]) {
                matchCount += 1;
            }
        }
        return matchCount;
    }

    // 设置结果
    function setResult(string _randomSeed) public onlyManager
    returns (bool success) {
        if (block.number - lastBlockHeight < voteGap) {
          return false;
        }
        bytes32 blockhash = block.blockhash(block.number-1);
        uint256 hash = uint256(keccak256(blockhash, _randomSeed, block.coinbase));
        bytes memory encode = new bytes(resultLength);
        for(uint8 i = 0; i < resultLength; i++) {
            uint256 rem = hash % 10;
            hash = hash / 10;
            encode[i] = table[rem];
        }
        string memory luckyNumber = new string(resultLength);
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
        if (matchCount < resultLength - 5) {
            paidRecord[_turn][_voter] = true;
            return;
        }

        uint totalCount = countRecord[_turn];
        uint qtumAmount = (10**uint(5+matchCount-resultLength) * qtumBaseAward);
        paidRecord[_turn][_voter] = true;
        _voter.transfer(qtumAmount);

        for (uint i=0; i < qrc20tokenList.length; i++) {
            uint tokenAmount = (10**uint(5+matchCount-resultLength) * tokenBaseAwardList[i]);
            QRC20Token token = qrc20tokenList[i];
            token.transfer(_voter, tokenAmount);
        }
        Paid(_turn, _voter);
    }

    // 获取所有奖金
    function getAllAward(address _voter) public {
        for (uint8 i=0; i < currentTurn; i++) {
            getAwardOfTurn(i, _voter);
        }
    }

    // 提取活动结束后 所有剩余的qtum和其他币
    function withdraw() public onlyManager {
        msg.sender.transfer(this.balance);
        for (uint i=0; i < qrc20tokenList.length; i++) {
            QRC20Token token = qrc20tokenList[i];
            token.transfer(msg.sender, token.balanceOf(this)-1); // ink issue
        }
    }

    // 添加qbao和beechat的账号地址
    function addApp(address _app) public onlyManager {
        appAddressList.push(_app);
    }

    // 删除地址
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

    // enable pay QTUM to this contract
    function () public payable {
        return;
    }
}
