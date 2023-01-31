import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main(): Promise<void> {
  const Logic: ContractFactory = await ethers.getContractFactory("StoreNFT");
  const logic: Contract = await upgrades.deployProxy(Logic, ["ST", "SNFT", "", "1", 2], { kind: "uups", initializer: "initialize" });
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
