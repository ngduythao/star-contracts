import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

const proxyAddress: string = "0xD59545650D7Da1d3a92352f8340791cE937FAabD";

async function main(): Promise<void> {
  console.log("Deploying LogicV2 contract...");
  const Logic: ContractFactory = await ethers.getContractFactory("StoreNFT");
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
