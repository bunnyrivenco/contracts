import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("BunnyRivenPrize", function () {
    const toBN = (number: number, decimal = 18) =>
        BigNumber.from(+number).mul(BigNumber.from(10).pow(decimal));
    const sig =
        "0x1556a70d76cc452ae54e83bb167a9041f0d062d000fa0dcb42593f77c544f6471643d14dbd6a6edc658f4b16699a585181a08dba4f6d16a9273e0e2cbed622da1b";

    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployEggFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const BunnyRiven = await ethers.getContractFactory("BunnyRiven");
        const bunnyRiven = await BunnyRiven.deploy();

        const Contract = await ethers.getContractFactory("BunnyRivenWheel");
        const contract = await Contract.deploy(
            bunnyRiven.address,
            bunnyRiven.address
        );

        await (
            await bunnyRiven.transfer(
                contract.address,
                ethers.utils.parseEther("1000")
            )
        ).wait();

        return { contract, owner, otherAccount, bunnyRiven };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { contract, owner } = await loadFixture(deployEggFixture);

            expect(await contract.owner()).to.equal(owner.address);
        });

        it("Should revert Invalid signature", async function () {
            const { contract, bunnyRiven, owner } = await loadFixture(
                deployEggFixture
            );

            const value = "1";
            await expect(
                contract.claim(
                    bunnyRiven.address,
                    ethers.utils.parseEther(value),
                    sig
                )
            ).to.be.revertedWith("Invalid signature");
        });
    });
});
