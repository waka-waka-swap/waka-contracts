const HDWalletProvider = require('@truffle/hdwallet-provider');
const mnemonic = ''
const id = ''

module.exports = {
  compilers: {
    solc: {
      version: "^0.6",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200
        }
      }
    }
  },
  plugins: ['truffle-plugin-verify'],
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    fantom: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rpc.ftm.tools'),
      network_id: 250,
      skipDryRun: true,
      networkCheckTimeout: 200000,
    },
    fantomtest: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rpc.testnet.fantom.network'),
      network_id: 4002,
      skipDryRun: true,
      networkCheckTimeout: 200000,
    },
    ropsten: {
      provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${id}`),
      network_id: 3,
      skipDryRun: true,
      networkCheckTimeout: 200000,
    }
  }
};
