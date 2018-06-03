pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";
import "openzeppelin-solidity/contracts/AddressUtils.sol";
import "openzeppelin-solidity/contracts/ReentrancyGuard.sol";

// import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ownership/Ownable.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/AddressUtils.sol";
// import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/ReentrancyGuard.sol";


contract Escrow is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using AddressUtils for address;

    uint256 internal fee = 1 finney;
    uint256 internal minimumGoal = 1 finney;
    uint256 internal earned = 0;

    // Terms in case of cancel
    enum Terms {
        BackToSender,
        BackToReceiver,
        HalfHalf
    }

    // Action of each party
    enum Action {
        None,
        Accept,
        Cancel
    }

    // Status of transaction
    enum Status {
        Ongoing,
        Fullfilled,
        Cancelled
    }

    // Transaction
    struct Transaction {
        address sender;
        address receiver;
        address broker;
        uint256 goal;
        uint256 paid;
        uint256 deadline;
        Terms terms;
        Action senderAction;
        Action receiverAction;
        Status status;
    }

    // List of transactions
    Transaction[] public transactions;

    // Events
    event NewTransaction(
        uint256 transactionId,
        address sender, 
        address receiver,
        address broker,
        uint256 goal,
        uint256 deadline,
        Terms terms
    );
    event AcceptTransaction(
        uint256 transactionId, 
        address party
    );
    event SendFunds(
        uint256 transactionId, 
        uint256 currentPaid, 
        uint256 totalPaid
    );
    event FulfillTransaction(uint256 transactionId);
    event CancelTransaction(
        uint256 transactionId, 
        address party
    );

    constructor() Ownable() public {}

    function createNewTransaction(
        address sender,
        address receiver,
        address broker,
        uint256 goal,
        uint256 deadline,
        Terms terms
    ) external payable nonReentrant() {
        require(!sender.isContract() && !receiver.isContract());
        if (broker != address(0)) {
            require(!broker.isContract());
            require(msg.value == fee.mul(2));
            broker.transfer(fee);
        }
        else {
            require(msg.value == fee);
        }
        require(goal >= minimumGoal);
        transactions.push(Transaction(
            sender,
            receiver,
            broker,
            goal,
            0,
            deadline,
            terms,
            Action.None,
            Action.None,
            Status.Ongoing
        ));
        earned = earned.add(fee);
        uint256 transactionId = transactions.length.sub(1);
        emit NewTransaction(
            transactionId, 
            sender, 
            receiver,
            broker, 
            goal, 
            deadline, 
            terms
        );
    }

    function sendFundsForTransaction(
        uint256 transactionId
    ) external payable nonReentrant() {
        Transaction storage currentTransaction = transactions[transactionId];
        uint256 paid = currentTransaction.paid.add(msg.value);
        require(msg.sender == currentTransaction.sender);
        require(paid <= currentTransaction.goal);
        currentTransaction.paid = paid;
        emit SendFunds(
            transactionId,
            msg.value,
            paid
        );
    }

    function accept(
        uint256 transactionId
    ) external nonReentrant() {
        // Validate transaction
        _validateTransaction(transactionId);

        // Accept transaction
        Transaction storage currentTransaction = transactions[transactionId];
        if (msg.sender == currentTransaction.sender) {
            currentTransaction.senderAction = Action.Accept;
        }
        else if (msg.sender == currentTransaction.receiver) {
            currentTransaction.receiverAction = Action.Accept;
        } else {
            revert();
        }
        emit AcceptTransaction(transactionId, msg.sender);

        // Finish transaction
        if (
            currentTransaction.senderAction == Action.Accept && 
            currentTransaction.receiverAction == Action.Accept
        ) {
            _finishTransaction(transactionId);
        }
    }

    function _validateTransaction(
        uint256 transactionId
    ) internal view {
        Transaction memory currentTransaction = transactions[transactionId];
        require(currentTransaction.status == Status.Ongoing);
        require(now <= currentTransaction.deadline);
        require(currentTransaction.paid == currentTransaction.goal);
        require(
            msg.sender == currentTransaction.sender ||
            msg.sender == currentTransaction.receiver
        );
    }

    function _finishTransaction(
        uint256 transactionId
    ) internal {
        Transaction storage currentTransaction = transactions[transactionId];
        currentTransaction.status = Status.Fullfilled;
        currentTransaction.receiver.transfer(currentTransaction.goal);
        emit FulfillTransaction(transactionId);
    }

    function cancel(
        uint256 transactionId
    ) external nonReentrant() {
        // Validate transaction
        _validateCancel(transactionId);

        // Cancel transaction
        _finishCancel(transactionId);
    }

    function _validateCancel(
        uint256 transactionId
    ) internal view {
        Transaction memory currentTransaction = transactions[transactionId];
        require(currentTransaction.status == Status.Ongoing);
        require(
            msg.sender == currentTransaction.sender ||
            msg.sender == currentTransaction.receiver
        );
    }

    function _finishCancel(
        uint256 transactionId
    ) internal {
        Transaction storage currentTransaction = transactions[transactionId];
        currentTransaction.status = Status.Cancelled;

        if (currentTransaction.terms == Terms.BackToSender) {
            currentTransaction.sender.transfer(currentTransaction.paid);
        }
        else if (currentTransaction.terms == Terms.BackToReceiver) {
            currentTransaction.receiver.transfer(currentTransaction.paid);
        }
        else if (currentTransaction.terms == Terms.HalfHalf) {
            uint256 half = currentTransaction.paid.div(2);
            currentTransaction.sender.transfer(half);
            currentTransaction.receiver.transfer(half);
        }

        emit CancelTransaction(transactionId, msg.sender);
    }

    function checkEarned() external view onlyOwner() returns (uint256) {
        return earned;
    }

    function withdraw() external onlyOwner() nonReentrant() {
        owner.transfer(earned);
        earned = 0;
    }

    function() public {
        // Do not accept ether, revert payments
        // If you want to donate send ether to 'owner' of contract
        revert();
    }
}
