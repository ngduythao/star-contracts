import { Contract, ContractFactory } from "ethers";
import { ethers, upgrades } from "hardhat";

async function main(): Promise<void> {
  const Logic: ContractFactory = await ethers.getContractFactory("StarClaim");
  const logic: Contract = await upgrades.deployProxy(Logic, ["StarClaim", "1", 1, ["0xe98a964eE6dA8E47C9c605D4D3616d4e2610d725"]], { kind: "uups", initializer: "initialize" });
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
