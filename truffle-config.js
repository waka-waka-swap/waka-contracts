const HDWalletProvider = require('truffle-hdwallet-provider');
const { mnemonic, infuraKey, ftmscan, etherscan } = require('./secret.json');

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
  api_keys: { ftmscan, etherscan },
  networks: {
    development: {
      host: "127.0.0.1",
      port: 7545,
      network_id: "*",
    },
    ftmtest: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rpc.testnet.fantom.network/'),
      network_id: 0xfa2
    },
    ftmmain: {
      provider: () => new HDWalletProvider(mnemonic, 'https://rpcapi.fantom.network'),
      network_id: 250,
    },
    ropsten: {
      provider: () => new HDWalletProvider(mnemonic, `https://ropsten.infura.io/v3/${infuraKey}`),
      network_id: 3,
      skipDryRun: true,
      networkCheckTimeout: 200000,
    }
  }
};
