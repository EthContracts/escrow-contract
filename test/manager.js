const Escrow = artifacts.require('Escrow.sol');

class Utils {
    finney(n) { return n * (10 ** 15); }
    ether(n) { return n * (10 ** 18); }
    days(n) { return n * (24 * 3600); }
    hours(n) { return n * 3600; }
    address0x0() { return '0x0000000000000000000000000000000000000000'; }

    mineBlock() {
        web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_mine',
        params: [],
        id: new Date().getTime()
        });
    }

    evmIncreaseTime(seconds) {
        web3.currentProvider.send({
        jsonrpc: '2.0',
        method: 'evm_increaseTime',
        params: [seconds],
        id: new Date().getTime()
        });
        this.mineBlock();
    }

    async throws(fn, ...args) {
        let thrown = false;
        try { await fn(...args); }
        catch (err) { thrown = true; }
        return thrown;
    }

    async watchForEvents(payload) {
        return new Promise((resolve, reject) => {
            const eventsFired = [];
            let watchContract = payload.watchContract || payload.contract;

            this.mineBlock();

            var eventSubscription = watchContract.allEvents({fromBlock: 'pending'}, (err, res) => {
                if (err) { reject(err); }
                else {
                    if (payload.eventNamesToWatch.includes(res.event)) {
                        eventsFired.push(res);
                    }

                    if (eventsFired.length === payload.expectedEventCount) {
                        eventSubscription.stopWatching();
                        resolve(eventsFired);
                    }
                }
            });

            payload.contract[payload.methodToCall](...payload.args);
        });
    }

    async promisify(fn, params) {
        return new Promise((resolve, reject) => {
            fn(params, (err, res) => {
                if (err) reject(err);
                else resolve(res);
            });
        });
    }
}

class Constants {
    constructor() {
        this.terms = {
            backToSender: 0,
            backToReceiver: 1,
            halfHalf: 2
        }
        this.action = {
            none: 0,
            accept: 1,
            cancel: 2
        }
        this.status = {
            ongoing: 0,
            fulfilled: 1,
            cancelled: 2
        }
    }
}

class Manager {
    constructor() {
        this.utils = new Utils();
        this.constants = new Constants();
    }

    async create() {
        let escrow = await Escrow.new();
        return escrow;
    }
}

module.exports = new Manager();
