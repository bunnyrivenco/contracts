import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("ERC721BunnyRivenNFTMarketPlace", function () {
    const toBN = (number: number, decimal = 18) =>
        BigNumber.from(+number).mul(BigNumber.from(10).pow(decimal));

    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployEggFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const BunnyRivenNFT = await ethers.getContractFactory("BunnyRivenNFT");
        const bunnyRivenNFT = await BunnyRivenNFT.deploy();

        bunnyRivenNFT.safeMint(owner.address, 0, "api/nfts/0");

        const Contract = await ethers.getContractFactory(
            "ERC721BunnyRivenNFTMarketPlace"
        );
        const contract = await Contract.deploy(
            owner.address,
            ethers.utils.parseEther("0.1"),
            ethers.utils.parseEther("10")
        );

        await (
            await contract.addCollection(bunnyRivenNFT.address, owner.address)
        ).wait();

        return { contract, bunnyRivenNFT, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { contract, owner } = await loadFixture(deployEggFixture);

            expect(await contract.owner()).to.equal(owner.address);
        });
    });

    describe("Trade NFT", function () {
        it("Should transfer BNB for seller", async function () {
            const { contract, bunnyRivenNFT, owner, otherAccount } =
                await loadFixture(deployEggFixture);

            const value = "1";
            await (await bunnyRivenNFT.approve(contract.address, 0)).wait();
            await (
                await contract.createAskOrder(
                    bunnyRivenNFT.address,
                    0,
                    ethers.utils.parseEther(value)
                )
            ).wait();
            await expect(
                contract
                    .connect(otherAccount)
                    .buyTokenUsingBNB(bunnyRivenNFT.address, 0, {
                        value: ethers.utils.parseEther(value),
                    })
            ).to.changeEtherBalances(
                [owner, otherAccount],
                [
                    ethers.utils.parseEther(value),
                    ethers.utils.parseEther("-" + value),
                ]
            );
        });
    });
});
