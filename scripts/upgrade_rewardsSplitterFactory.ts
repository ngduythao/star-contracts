import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

const proxyAddress: string = "0xE6baF8136e6B271d1C04eA2B80906D1dE80e816f";

async function main(): Promise<void> {
  console.log("Deploying LogicV2 contract...");
  const Logic: ContractFactory = await ethers.getContractFactory("RewardSplitterFactory");
  const logic: Contract = await upgrades.upgradeProxy(proxyAddress, Logic);
  await logic.deployed();
  console.log("Logic Proxy Contract deployed to : ", logic.address);
  console.log("Logic Contract implementation address is : ", await upgrades.erc1967.getImplementationAddress(logic.address));
}

main()
  .then(() => process.exit(0))
  .catch((error: Error) => {
    console.error(error);
    process.exit(1);
  });
