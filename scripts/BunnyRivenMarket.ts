import { ethers } from "hardhat";

async function main() {
    const Contract = await ethers.getContractFactory("BunnyRivenMarket");
    const contract = await Contract.deploy(
        "0xF1B5F2ECC5108607eF0EC5dE8cB36DB1f7a72384",
        "0xf4efb0D6e1aCa9442e48E16f42Dce2D492cEf788"
    );

    await contract.deployed();
    console.log(`Bunny Riven Market deployed to ${contract.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
