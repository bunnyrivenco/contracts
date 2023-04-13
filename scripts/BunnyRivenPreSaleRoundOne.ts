import { ethers } from "hardhat";

async function main() {
    const Contract = await ethers.getContractFactory(
        "BunnyRivenPreSaleRoundOne"
    );
    const startTime = 1670517600;
    const endTime = 365; // days
    const data = [
        "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526",
        "0x1846f1435ee1fff97c50Fef34837A31DD033C06B",
        "0xf4efb0D6e1aCa9442e48E16f42Dce2D492cEf788",
        ethers.utils.parseEther("1").toString(),
        ethers.utils.parseEther("100").toString(),
        startTime,
        endTime,
    ];
    console.log("data", ...data);
    const contract = await Contract.deploy(
        "0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526",
        "0x1846f1435ee1fff97c50Fef34837A31DD033C06B",
        "0xf4efb0D6e1aCa9442e48E16f42Dce2D492cEf788",
        ethers.utils.parseEther("1"),
        ethers.utils.parseEther("100").toString(),
        startTime,
        endTime
    );

    await contract.deployed();
    console.log(`Bunny Riven PreSale deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
