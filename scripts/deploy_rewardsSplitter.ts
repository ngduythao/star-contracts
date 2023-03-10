import { Contract, ContractFactory } from "ethers";
import { ethers } from "hardhat";

async function main(): Promise<void> {
  const Factory: ContractFactory = await ethers.getContractFactory("RewardSplitter");
  const contract: Contract = await Factory.deploy();
  await contract.deployed();
  console.log("Contract deployed to : ", contract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
