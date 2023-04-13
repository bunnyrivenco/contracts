import { ethers } from "hardhat";

async function main() {
    const Contract = await ethers.getContractFactory("BunnyRivenWheel");
    const contract = await Contract.deploy(
        "0xf4efb0D6e1aCa9442e48E16f42Dce2D492cEf788",
        "0xf4efb0D6e1aCa9442e48E16f42Dce2D492cEf788"
    );

    await contract.deployed();
    console.log(`Bunny Riven Wheel deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
