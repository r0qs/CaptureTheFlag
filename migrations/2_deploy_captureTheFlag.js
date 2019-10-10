const CTF = artifacts.require("CaptureTheFlag");
const Log = artifacts.require("Log");

module.exports = async function (deployer, network, accounts) {
  return deployer.then(async () => {
    if (/(local)/.test(deployer.network)) {
      await deployer.deploy(Log);
      const logContract = await Log.deployed();

      await deployer.deploy(CTF, logContract.address, { from: accounts[0] })
    }
  })
}