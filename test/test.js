const Manager = require('./manager');

contract('Escrow', (accounts) => {
    let escrow;

    beforeEach(async () => {
        escrow = await Manager.create();
    })

    it('test new transaction', async () => {
        let owner = accounts[0];
        let sender = accounts[1];
        let receiver = accounts[2];
        let address0x0 = Manager.utils.address0x0();
        let broker = accounts[3];
        let goal = Manager.utils.finney(1);
        let deadline = Manager.utils.hours(1);
        let terms = Manager.constants.terms.backToSender;

        assert.equal(
            await escrow.owner.call(), owner,
            'Owner address should match'
        );

        let events = await Manager.utils.watchForEvents({
            contract: escrow,
            methodToCall: 'createNewTransaction',
            args: [
                sender,
                receiver,
                address0x0,
                goal,
                deadline,
                terms,
                {from: sender, value: Manager.utils.finney(1)}
            ],
            eventNamesToWatch: ['NewTransaction'],
            expectedEventCount: 1,
        });

        assert.equal(parseInt(events[0].args.transactionId), 0,
            'Transaction id should match'
        );
        assert.equal(events[0].args.sender, sender,
            'Sender should match'
        );
        assert.equal(events[0].args.receiver, receiver,
            'Receiver should match'
        );
        assert.equal(events[0].args.broker, address0x0,
            'Broker should match'
        );
        assert.equal(parseInt(events[0].args.goal), goal,
            'Goal should match'
        );
        assert.equal(parseInt(events[0].args.deadline), deadline,
            'Deadline should match'
        );
        assert.equal(parseInt(events[0].args.terms), terms,
            'Terms should match'
        );
    });
});
