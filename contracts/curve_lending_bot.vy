# @version 0.3.7

struct FeeData:
    refund_wallet: address
    gas_fee: uint256
    service_fee_collector: address
    service_fee: uint256

interface ControllerFactory:
    def get_controller(collateral: address) -> address: view

interface Controller:
    def create_loan(collateral: uint256, debt: uint256, N: uint256): payable
    def add_collateral(collateral: uint256): payable
    def remove_collateral(collateral: uint256): nonpayable
    def borrow_more(collateral: uint256, debt: uint256): payable
    def repay(_d_debt: uint256): nonpayable
    def health(user: address) -> int256: view
    def loan_exists(user: address) -> bool: view
    def user_state(user: address) -> uint256[4]: view

interface ERC20:
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def decimals() -> uint256: view
    def approve(_spender: address, _value: uint256) -> bool: nonpayable
    def balanceOf(_from: address) -> uint256: view

interface Factory:
    def fee_data() -> FeeData: view
    def create_loan_event(collateral: address, collateral_amount: uint256, lend_amount: uint256, debt: uint256, withdraw_amount: uint256, health_threshold: int256, expire: uint256, repayable: bool): nonpayable
    def add_collateral_event(collateral: address, collateral_amount: uint256, lend_amount: uint256): nonpayable
    def repay_event(collateral: address, input_amount: uint256, repay_amount: uint256): nonpayable
    def remove_collateral_event(collateral: address, collateral_amount: uint256, withdraw_amount: uint256): nonpayable
    def withdraw_event(collateral: address, withdraw_amount: uint256): nonpayable
    def borrow_more_event(collateral: address, lend_amount: uint256, withdraw_amount: uint256): nonpayable
    def bot_start_event(collateral: address, health_threshold: int256, expire: uint256, repayable: bool): nonpayable

DENOMINATOR: constant(uint256) = 10000
FACTORY: immutable(address)
CONTROLLER_FACTORY: immutable(address)
OWNER: immutable(address)
WETH: immutable(address)
crvUSD: immutable(address)

@external
def __init__(controller_factory: address, weth: address, crv_usd: address, owner: address):
    FACTORY = msg.sender
    CONTROLLER_FACTORY = controller_factory
    WETH = weth
    crvUSD = crv_usd
    OWNER = owner

@internal
def _safe_approve(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("approve(address,uint256)")),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def _safe_transfer(_token: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_to, _value, method_id=method_id("transfer(address,uint256)")),
        max_outsize=32
    )  # dev: failed approve
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed approve

@internal
def _safe_transfer_from(_token: address, _from: address, _to: address, _value: uint256):
    _response: Bytes[32] = raw_call(
        _token,
        _abi_encode(_from, _to, _value, method_id=method_id("transferFrom(address,address,uint256)")),
        max_outsize=32
    )  # dev: failed transferFrom
    if len(_response) > 0:
        assert convert(_response, bool) # dev: failed transferFrom

@external
@payable
@nonreentrant('lock')
def create_loan(collateral: address, collateral_amount: uint256, lend_amount: uint256, debt: uint256, withdraw_amount: uint256, N: uint256, health_threshold: int256, expire: uint256, repayable: bool):
    assert msg.sender == OWNER, "Unauthorized"
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    fee_data: FeeData = Factory(FACTORY).fee_data()
    fee_amount: uint256 = unsafe_div(collateral_amount * fee_data.service_fee, DENOMINATOR)
    _lend_amount: uint256 = lend_amount
    if _lend_amount > collateral_amount - fee_amount:
        _lend_amount = unsafe_sub(collateral_amount, fee_amount)
    if collateral == WETH:
        assert msg.value >= collateral_amount, "Insufficient ETH"
        if msg.value > collateral_amount:
            send(OWNER, unsafe_sub(msg.value, collateral_amount))
        if fee_amount > 0:
            send(fee_data.service_fee_collector, fee_amount)
        Controller(controller).create_loan(_lend_amount, debt, N, value=_lend_amount)
    else:
        self._safe_transfer_from(collateral, OWNER, self, collateral_amount)
        if fee_amount > 0:
            self._safe_transfer(collateral, fee_data.service_fee_collector, fee_amount)
        self._safe_approve(collateral, controller, _lend_amount)
        Controller(controller).create_loan(_lend_amount, debt, N)
    if withdraw_amount > 0:
        ERC20(crvUSD).transfer(OWNER, withdraw_amount)
    Factory(FACTORY).create_loan_event(collateral, collateral_amount, lend_amount, debt, withdraw_amount, health_threshold, expire, repayable)

@external
@payable
@nonreentrant('lock')
def add_collateral(collateral: address, collateral_amount: uint256, lend_amount: uint256):
    assert msg.sender == OWNER or msg.sender == FACTORY, "Unauthorized"
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    fee_data: FeeData = Factory(FACTORY).fee_data()
    if collateral == WETH:
        if collateral_amount > 0 and fee_data.service_fee > 0:
            send(fee_data.service_fee_collector, unsafe_div(collateral_amount * fee_data.service_fee, DENOMINATOR))
        if lend_amount > 0:
            assert self.balance >= lend_amount, "Insufficient balance"
            Controller(controller).add_collateral(lend_amount, value=lend_amount)
    else:
        if collateral_amount > 0:
            self._safe_transfer_from(collateral, OWNER, self, collateral_amount)
            if fee_data.service_fee > 0:
                self._safe_transfer(collateral, fee_data.service_fee_collector, unsafe_div(collateral_amount * fee_data.service_fee, DENOMINATOR))
        if lend_amount > 0:
            assert ERC20(collateral).balanceOf(self) >= lend_amount, "Insufficient balance"
            self._safe_approve(collateral, controller, lend_amount)
            Controller(controller).add_collateral(lend_amount)
    if msg.sender == FACTORY:
        assert self.balance >= fee_data.gas_fee, "Insufficient gas fee"
        send(fee_data.refund_wallet, fee_data.gas_fee)
    else:
        Factory(FACTORY).add_collateral_event(collateral, collateral_amount, lend_amount)

@external
@nonreentrant('lock')
def remove_collateral(collateral: address, collateral_amount: uint256, withdraw_amount: uint256):
    assert msg.sender == OWNER, "Unauthorized"
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    if collateral_amount > 0:
        Controller(controller).remove_collateral(collateral_amount)
    if withdraw_amount > 0:
        if collateral == WETH:
            send(OWNER, withdraw_amount)
        else:
            self._safe_transfer(collateral, OWNER, withdraw_amount)
    Factory(FACTORY).remove_collateral_event(collateral, collateral_amount, withdraw_amount)

@external
@payable
def borrow_more(collateral: address, collateral_amount: uint256, lend_amount: uint256, debt: uint256, withdraw_amount: uint256):
    assert msg.sender == OWNER, "Unauthorized"
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    if collateral == WETH:
        Controller(controller).borrow_more(lend_amount, debt, value=lend_amount)
    else:
        self._safe_transfer_from(collateral, OWNER, self, collateral_amount)
        self._safe_approve(collateral, controller, lend_amount)
        Controller(controller).borrow_more(lend_amount, debt)
    ERC20(crvUSD).transfer(OWNER, withdraw_amount)
    Factory(FACTORY).borrow_more_event(collateral, lend_amount, withdraw_amount)

@external
def repay(collateral: address, input_amount: uint256, repay_amount: uint256):
    assert msg.sender == OWNER or msg.sender == FACTORY, "Unauthorized"
    fee_data: FeeData = Factory(FACTORY).fee_data()
    if msg.sender == OWNER and input_amount > 0:
        ERC20(crvUSD).transferFrom(OWNER, self, input_amount)
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    ERC20(crvUSD).approve(controller, repay_amount)
    Controller(controller).repay(repay_amount)
    if msg.sender == FACTORY:
        assert self.balance >= fee_data.gas_fee, "Insufficient gas fee"
        send(fee_data.refund_wallet, fee_data.gas_fee)
    else:
        Factory(FACTORY).repay_event(collateral, input_amount, repay_amount)

@external
def withdraw_crvusd(amount: uint256):
    assert msg.sender == OWNER, "Unauthorized"
    ERC20(crvUSD).transfer(OWNER, amount)
    Factory(FACTORY).withdraw_event(crvUSD, amount)

@external
def bot_restart(collateral: address, health_threshold: int256, expire: uint256, repayable: bool):
    Factory(FACTORY).bot_start_event(collateral, health_threshold, expire, repayable)

@external
@view
def health(collateral: address) -> int256:
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    return Controller(controller).health(self)

@external
@view
def loan_exists(collateral: address) -> bool:
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    return Controller(controller).loan_exists(self)

@external
@view
def state(collateral: address) -> uint256[4]:
    controller: address = ControllerFactory(CONTROLLER_FACTORY).get_controller(collateral)
    return Controller(controller).user_state(self)

@external
@payable
def __default__():
    assert msg.sender == OWNER or msg.sender == ControllerFactory(CONTROLLER_FACTORY).get_controller(WETH), "ETH receive"
