const HDWalletProvider = require("@truffle/hdwallet-provider");
module.exports = {
  networks: {
    development: {
     host: "127.0.0.1",
     port: 8545,
     network_id: "*"
    },
    sepolia: {
      provider: () => {
        return new HDWalletProvider(process.env.MNEMONIC, 'https://sepolia.infura.io/v3/7057752b7f16403db4b4e004bdd4f5f7')
      },
      network_id: '11155111', // eslint-disable-line camelcase
      gas: 4465030,
      gasPrice: 10000000000,
    },
  },
  compilers: {
    solc: {
      version: "0.8.13",
    }
  },
  db: {
    enabled: false,
    host: "127.0.0.1",
  }
};
