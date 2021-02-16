import "@nomiclabs/hardhat-waffle";
import "solidity-coverage";
import "hardhat-spdx-license-identifier";
import "hardhat-gas-reporter";
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

export default {
  gasReporter: {
    enabled: true,
    currency: "USD",
    gasPrice: 100,
    outputFile: "gasReport.txt",
    rst: true,
    rstTitle: "armor-core gas report"
  },
  spdxLicenseIdentifier: {
    overwrite: false,
    runOnCompile: true,
  },
  solidity: {
    compilers :[
      {
        version: "0.6.12",
        settings: {
          optimizer : {
            enabled: true,
            runs: 200
          }
        }
      },
      {
        version: "0.5.17",
        settings: {
          optimizer : {
            enabled: true,
            runs: 200
          }
        }
      }
    ]
  },
  networks: {
    hardhat: {
      gas: 10000000,
      accounts: {
        accountsBalance: "1000000000000000000000000"
      },
      allowUnlimitedContractSize: true,
      timeout: 1000000,
      forking: {
        url: "https://eth-mainnet.alchemyapi.io/v2/90dtUWHmLmwbYpvIeC53UpAICALKyoIu",
        blockNumber: 11861166
      }
    },
    coverage: {
      url: 'http://localhost:8555'
    }
  }
};

