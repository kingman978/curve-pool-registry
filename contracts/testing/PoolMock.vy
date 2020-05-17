"""
@notice Mock Curve pool for testing
"""

FEE_PRECISION: constant(uint256) = 10**10

contract ERC20Mock:
    def decimals() -> uint256: constant
    def _mint_for_testing(_amount: uint256) -> bool: modifying

n_coins: int128
coin_list: address[4]
underlying_coin_list: address[4]

A: public(uint256)
fee: public(uint256)


@public
def __init__(
    _n_coins: int128,
    _coin_list: address[4],
    _underlying_coin_list: address[4],
    _A: uint256,
    _fee: uint256,
):
    self.n_coins = _n_coins
    self.coin_list = _coin_list
    self.underlying_coin_list = _underlying_coin_list
    self.A = _A
    self.fee = _fee


@public
@constant
def coins(i: int128) -> address:
    assert i < self.n_coins  # dev: exceeds n_coins
    return self.coin_list[i]


@public
@constant
def underlying_coins(i: int128) -> address:
    assert i < self.n_coins  # dev: exceeds n_coins
    return self.underlying_coin_list[i]


@private
@constant
def _get_dy(_from: address, _to: address, _dx: uint256) -> uint256:
    _from_precision: uint256 = ERC20Mock(_from).decimals()
    _to_precision: uint256 = ERC20Mock(_to).decimals()
    _dy: uint256 = _dx * (10**_to_precision) / (10**_from_precision)
    _fee: uint256 = _dy * self.fee / FEE_PRECISION

    return _dy - _fee


@public
@constant
def get_dy(i: int128, j: int128, dx: uint256) -> uint256:
    return self._get_dy(self.coin_list[i], self.coin_list[j], dx)


@public
@constant
def get_dy_underlying(i: int128, j: int128, dx: uint256) -> uint256:
    return self._get_dy(self.underlying_coin_list[i], self.underlying_coin_list[j], dx)


@private
def _exchange(_sender: address, _from: address, _to: address, dx: uint256, min_dy: uint256):
    dy: uint256 = self._get_dy(_from, _to, dx)
    assert dy >= min_dy, "Exchange resulted in fewer coins than expected"

    _response: bytes[32] = raw_call(
        _from,
        concat(
            method_id("transferFrom(address,address,uint256)", bytes[4]),
            convert(_sender, bytes32),
            convert(self, bytes32),
            convert(dx, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) != 0:
        assert convert(_response, bool)

    ERC20Mock(_to)._mint_for_testing(dy)

    _response = raw_call(
        _to,
        concat(
            method_id("transfer(address,uint256)", bytes[4]),
            convert(_sender, bytes32),
            convert(dy, bytes32)
        ),
        max_outsize=32
    )
    if len(_response) != 0:
        assert convert(_response, bool)


@public
@nonreentrant('lock')
def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256):
    self._exchange(msg.sender, self.coin_list[i], self.coin_list[j], dx, min_dy)


@public
@nonreentrant('lock')
def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256):
    self._exchange(msg.sender, self.underlying_coin_list[i], self.underlying_coin_list[j], dx, min_dy)


# testing functions

@public
def _set_A(_value: uint256):
    self.A = _value


@public
def _set_fee(_value: uint256):
    self.fee = _value
