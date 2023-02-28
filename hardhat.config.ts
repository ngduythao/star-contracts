import "@nomicfoundation/hardhat-toolbox";
import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import { config as dotenvConfig } from "dotenv";
import "hardhat-contract-sizer";
import "hardhat-gas-reporter";
import type { HardhatUserConfig } from "hardhat/config";
import type { NetworkUserConfig } from "hardhat/types";
import { resolve } from "path";

import "./tasks/accounts";

// import "./tasks/deploy";

const dotenvConfigPath: string = process.env.DOTENV_CONFIG_PATH || "./.env";
dotenvConfig({ path: resolve(__dirname, dotenvConfigPath) });

// Ensure that we have all the environment variables we need.
const mnemonic: string | undefined = process.env.MNEMONIC;
if (!mnemonic) {
  throw new Error("Please set your MNEMONIC in a .env file");
}

const infuraApiKey: string | undefined = process.env.INFURA_API_KEY;
if (!infuraApiKey) {
  throw new Error("Please set your INFURA_API_KEY in a .env file");
}

const chainIds = {
  mainnet: 1,
  goerli: 5,
  avalanche: 43114,
  fuji: 43113,
  bsc: 56,
  tbsc: 97,
  tomo: 88,
  tomot: 89,
  polygon: 137,
  mumbai: 80001,
  wraptag: 24052022,
};

function getChainConfig(chain: keyof typeof chainIds): NetworkUserConfig {
  let jsonRpcUrl: string;
  switch (chain) {
    case "goerli":
      jsonRpcUrl = process.env.GOERLI_URL || "";
      break;
    case "avalanche":
      jsonRpcUrl = process.env.AVAX_URL || "";
      break;
    case "fuji":
      jsonRpcUrl = process.env.FUJI_URL || "";
      break;
    case "bsc":
      jsonRpcUrl = process.env.BSC_URL || "";
      break;
    case "tbsc":
      jsonRpcUrl = process.env.BSCT_URL || "";
      break;
    case "polygon":
      jsonRpcUrl = process.env.POLYGON || "";
      break;
    case "mumbai":
      jsonRpcUrl = process.env.MUMBAI || "";
      break;
    case "tomo":
      jsonRpcUrl = process.env.TOMO_URL || "";
      break;
    case "tomot":
      jsonRpcUrl = process.env.TOMOT_URL || "";
      break;
    case "wraptag":
      jsonRpcUrl = process.env.WRAPTAG_URL || "";
      break;
    default:
      jsonRpcUrl = "https://" + chain + ".infura.io/v3/" + infuraApiKey;
  }
  return {
    accounts: process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    chainId: chainIds[chain],
    url: jsonRpcUrl,
  };
}

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  etherscan: {
    apiKey: {
      mainnet: process.env.ETHERSCAN_API_KEY || "",
      goerli: process.env.ETHERSCAN_API_KEY || "",
      avalanche: process.env.SNOWTRACE_API_KEY || "",
      avalancheFujiTestnet: process.env.SNOWTRACE_API_KEY || "",
      bsc: process.env.BSCSCAN_API_KEY || "",
      bscTestnet: process.env.BSCSCAN_API_KEY || "",
      polygon: process.env.POLYGONSCAN_API_KEY || "",
      polygonMumbai: process.env.POLYGONSCAN_API_KEY || "",
    },
  },
  gasReporter: {
    currency: "USD",
    enabled: process.env.REPORT_GAS ? true : false,
    excludeContracts: [],
    src: "./contracts",
  },
  networks: {
    mainnet: getChainConfig("mainnet"),
    goerli: getChainConfig("goerli"),
    avalanche: getChainConfig("avalanche"),
    fuji: getChainConfig("fuji"),
    bsc: getChainConfig("bsc"),
    tbsc: getChainConfig("tbsc"),
    tomo: getChainConfig("tomo"),
    ttomo: getChainConfig("tomot"),
    polygon: getChainConfig("polygon"),
    mumbai: getChainConfig("mumbai"),
    wraptag: getChainConfig("wraptag"),
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
  solidity: {
    version: "0.8.19",
    settings: {
      metadata: {
        bytecodeHash: "none",
      },
      optimizer: {
        enabled: true,
        runs: 40699,
      },
    },
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  contractSizer: {
    alphaSort: true,
    runOnCompile: true,
    disambiguatePaths: false,
  },
};

export default config;
