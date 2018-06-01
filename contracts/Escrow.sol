pragma solidity 0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/ownership/Ownable.sol";


contract Escrow is Ownable {
    using SafeMath for uint256;

    uint256 internal fee = 10 finney;
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
        uint256 goal,
        uint256 deadline,
        Terms terms
    ) external payable returns (uint256) {
        require(msg.value == fee);
        transactions.push(Transaction(
            sender,
            receiver,
            goal,
            0,
            deadline,
            terms,
            Action.None,
            Action.None,
            Status.Ongoing
        ));
        earned = earned.add(msg.value);
        uint256 transactionId = transactions.length.sub(1);
        emit NewTransaction(
            transactionId, 
            sender, 
            receiver, 
            goal, 
            deadline, 
            terms
        );
        return transactionId;
    }

    function sendFundsForTransaction(
        uint256 transactionId
    ) external payable {
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
    ) external {
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
    ) external {
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

    function withdraw() external onlyOwner() {
        owner.transfer(earned);
        earned = 0;
    }
}