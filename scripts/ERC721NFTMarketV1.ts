import { ethers } from "hardhat";

async function main() {
    const Contract = await ethers.getContractFactory(
        "ERC721BunnyRivenNFTMarketV1"
    );
    const contract = await Contract.deploy(
        "0x05bBB973F634c27435319CA772813CcC46059b35",
        "0xae13d989dac2f0debff460ac112a837c89baa7cd",
        ethers.utils.parseEther("0.1"),
        ethers.utils.parseEther("10")
    );

    await contract.deployed();
    console.log(`Bunny Riven Market deployed to ${contract.address}`);
    // yarn v_bsc_test 0x3509F4E4f61327F61C112BCF5c4701013329a992 0x05bBB973F634c27435319CA772813CcC46059b35 0xae13d989dac2f0debff460ac112a837c89baa7cd 100000000000000000 10000000000000000000
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
