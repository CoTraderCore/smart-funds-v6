// This contract sell/buy UNI and BNT Pool relays for DAI mock token
pragma solidity ^0.6.0;

import "../../../contracts/core/interfaces/ITokensTypeStorage.sol";
import "../../../contracts/zeppelin-solidity/contracts/math/SafeMath.sol";
import "../../../contracts/zeppelin-solidity/contracts/token/ERC20/IERC20.sol";


contract PoolPortalMock {

  using SafeMath for uint256;

  ITokensTypeStorage public tokensTypes;

  address public DAI;
  address public BNT;
  address public DAIBNTPoolToken;
  address public DAIUNIPoolToken;

  enum PortalType { Bancor, Uniswap }

  // KyberExchange recognizes ETH by this address, airswap recognizes ETH as address(0x0)
  IERC20 constant private ETH_TOKEN_ADDRESS = IERC20(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);
  address constant private NULL_ADDRESS = address(0);

  constructor(
    address _BNT,
    address _DAI,
    address _DAIBNTPoolToken,
    address _DAIUNIPoolToken,
    address _tokensTypes
  )
    public
  {
    DAI = _DAI;
    BNT = _BNT;
    DAIBNTPoolToken = _DAIBNTPoolToken;
    DAIUNIPoolToken = _DAIUNIPoolToken;
    tokensTypes = ITokensTypeStorage(_tokensTypes);
  }


  // for mock 1 Relay BNT = 0.5 BNT and 0.5 ERC
  function buyBancorPool(IERC20 _poolToken, uint256 _amount) private {
     uint256 relayAmount = _amount.div(2);

     require(IERC20(BNT).transferFrom(msg.sender, address(this), relayAmount));
     require(IERC20(DAI).transferFrom(msg.sender, address(this), relayAmount));

     IERC20(DAIBNTPoolToken).transfer(msg.sender, _amount);

     setTokenType(address(_poolToken), "BANCOR_ASSET");
  }

  // for mock 1 UNI = 0.5 ETH and 0.5 ERC
  function buyUniswapPool(address _poolToken, uint256 _ethAmount) private {
    require(IERC20(DAI).transferFrom(msg.sender, address(this), _ethAmount));
    IERC20(DAIUNIPoolToken).transfer(msg.sender, _ethAmount.mul(2));

    setTokenType(_poolToken, "UNISWAP_POOL");
  }


  function buyPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      buyBancorPool(_poolToken, _amount);
    }
    else if (_type == uint(PortalType.Uniswap)){
      require(_amount == msg.value, "Not enough ETH");
      buyUniswapPool(address(_poolToken), _amount);
    }
    else{
      // unknown portal type
      revert();
    }
  }

  function getBancorConnectorsByRelay(address relay)
  public
  view
  returns(
    IERC20 BNTConnector,
    IERC20 ERCConnector
  )
  {
    BNTConnector = IERC20(BNT);
    ERCConnector = IERC20(DAI);
  }

  function getUniswapConnectorsAmountByPoolAmount(
    uint256 _amount,
    address _exchange
  )
  public
  view
  returns(uint256 ethAmount, uint256 ercAmount){
    ethAmount = _amount.div(2);
    ercAmount = _amount.div(2);
  }


  function getTokenByUniswapExchange(address _exchange)
  public
  view
  returns(address){
    return DAI;
  }


  function sellPool
  (
    uint256 _amount,
    uint _type,
    IERC20 _poolToken
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      sellPoolViaBancor(_poolToken, _amount);
    }
    else if (_type == uint(PortalType.Uniswap)){
      sellPoolViaUniswap(_poolToken, _amount);
    }
    else{
      // unknown portal type
      revert();
    }
  }


  function sellPoolViaBancor(IERC20 _poolToken, uint256 _amount) private {
    // get BNT pool relay back
    require(IERC20(DAIBNTPoolToken).transferFrom(msg.sender, address(this), _amount));

    // send back connectors
    require(IERC20(DAI).transfer(msg.sender, _amount.div(2)));
    require(IERC20(BNT).transfer(msg.sender, _amount.div(2)));
  }

  function sellPoolViaUniswap(IERC20 _poolToken, uint256 _amount) private {
    // get UNI pool back
    require(IERC20(DAIUNIPoolToken).transferFrom(msg.sender, address(this), _amount));

    // send back connectors
    require(IERC20(DAI).transfer(msg.sender, _amount.div(2)));
    payable(address(msg.sender)).transfer(_amount.div(2));
  }

  // Pool portal can mark each pool token as UNISWAP or BANCOR
  function setTokenType(address _token, string memory _type) private {
    // no need add type, if token alredy registred
    if(tokensTypes.isRegistred(_token))
      return;

    tokensTypes.addNewTokenType(_token,  _type);
  }

  function pay() public payable {}

  fallback() external payable {}
}
