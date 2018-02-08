pragma solidity ^0.4.19;

contract SatelliteContract {

    address contractManager; // 卫星
    uint8 public currentTurn; // 当前开奖轮次
    uint public lastBlockHeight; // 上一轮的开奖区块高度
    uint public voteGap = 1000;
    uint8 resultLength = 5;
    bytes table = "0123456789";
    mapping(uint8 => string) public resultOf; // 随机数结果记录

    event ResultSet(uint8 indexed _turn, string _randomSeed, string _luckyNumber);

    modifier onlyManager() {
        require(msg.sender == contractManager);
        _;
    }

    function SatelliteContract() public {
        contractManager = msg.sender;
        lastBlockHeight = 0;
        currentTurn = 0;

    }

    // 设置结果
    function setResult(string _randomSeed) public onlyManager
    returns (bool success) {
        if (block.number - lastBlockHeight < voteGap) {
          return false;
        }
        uint256 hash = uint256(keccak256(block.timestamp, _randomSeed, block.coinbase));
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

    // disable pay QTUM to this contract
    function () public payable {
        revert();
    }
}
