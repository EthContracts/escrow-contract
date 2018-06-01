const HDWalletProvider = require('truffle-hdwallet-provider');
const DotEnv = require('dotenv');

DotEnv.config();
const mnemonic = process.env.MNEMONIC;

const infuraToken = 'IMsVbCijmt9z4RnBadCo';

function gwei(n) { return n * (10 ** 9); }
function mwei(n) { return n * (10 ** 6); }

const gasLimit = mwei(6);
const gasPrice = gwei(30);

module.exports = {
    networks: {
        ganache: {
            host: 'localhost',
            port: 7545,
            network_id: '*', // Match any network id
        },
        ropsten: {
            network_id: 3, // Official ropsten network id
            provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/${infuraToken}`),
            gas: gasLimit,
            gasPrice: gasPrice,
        },
        kovan: {
            network_id: 42, // Official kovan network id
            provider: () => new HDWalletProvider(mnemonic, `https://kovan.infura.io/${infuraToken}`),
            gas: gasLimit,
            gasPrice: gasPrice,
        },
        rinkeby: {
            network_id: 4, // Official rinkeby network id
            provider: () => new HDWalletProvider(mnemonic, `https://rinkeby.infura.io/${infuraToken}`),
            gas: gasLimit,
            gasPrice: gasPrice,
        },
        mainnet: {
            network_id: 1, // Official main network id
            provider: () => new HDWalletProvider(mnemonic, `https://mainnet.infura.io/${infuraToken}`),
            gas: gasLimit,
            gasPrice: gasPrice,
        }
    },
    mocha: {
        reporter: 'eth-gas-reporter',
    }
};