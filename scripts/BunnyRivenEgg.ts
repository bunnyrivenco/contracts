import { ethers } from "hardhat";

async function main() {
    const Contract = await ethers.getContractFactory("BunnyRivenEgg");
    const contract = await Contract.deploy(
        "0x1846f1435ee1fff97c50Fef34837A31DD033C06B"
    );

    await contract.deployed();
    console.log(`Bunny Riven Egg deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
