const Escrow = artifacts.require("./Escrow.sol");
const fs = require('fs');

module.exports = (deployer, network) => {
    let target = Escrow;
    deployer.deploy(target).then(() => {
        fs.writeFileSync('.deployed', JSON.stringify({escrow: target.address}));
    });
};
