import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

const proxyAddress: string = "0xAd7a0B3f744f177E3f1fe6b315Dbd79b3ce89668";

async function main(): Promise<void> {
  console.log("Deploying LogicV2 contract...");
  const Logic: ContractFactory = await ethers.getContractFactory("StarNFT");
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
