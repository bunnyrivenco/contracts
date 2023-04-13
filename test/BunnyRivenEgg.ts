import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("BunnyRivenEgg", function () {
    const toBN = (number: number, decimal = 18) =>
        BigNumber.from(+number).mul(BigNumber.from(10).pow(decimal));

    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployEggFixture() {
        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const BunnyRiven = await ethers.getContractFactory("BunnyRiven");
        const bunnyRiven = await BunnyRiven.deploy();

        const Egg = await ethers.getContractFactory("BunnyRivenEgg");
        const egg = await Egg.deploy(bunnyRiven.address);

        return { egg, bunnyRiven, owner, otherAccount };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { egg, owner } = await loadFixture(deployEggFixture);

            expect(await egg.owner()).to.equal(owner.address);
        });
    });

    describe("Buy Eggs", function () {
        it("Should transfer the price buy egg to the contract", async function () {
            const { egg, bunnyRiven, owner, otherAccount } = await loadFixture(
                deployEggFixture
            );
            await (await bunnyRiven.approve(egg.address, toBN(1000000))).wait();

            const balance = await bunnyRiven.balanceOf(owner.address);
            const qty = 5;
            const totalPrice = toBN(80).mul(5);
            await (await egg.buyEgg(qty, "0")).wait();

            const newBalance = await bunnyRiven.balanceOf(owner.address);
            const balanceContract = await bunnyRiven.balanceOf(egg.address);
            expect(newBalance).to.equal(balance.sub(totalPrice));
            expect(balanceContract).to.equal(totalPrice);

            expect(
                await egg["eggOf(address,string)"](owner.address, "0")
            ).to.equal(qty);

            expect(await egg.totalSell()).to.equal(qty);
            expect(await egg.TOTAL_SUPPLY()).to.equal(5000);

            expect(
                egg
                    .connect(otherAccount)
                    ["eggOf(address,string)"](owner.address, "0")
            ).to.be.revertedWith("Caller is not the owner");

            expect(
                await egg["eggOf(address,string)"](otherAccount.address, "0")
            ).to.equal(0);
        });

        it("Should revert error buy egg", async function () {
            const { egg } = await loadFixture(deployEggFixture);
            await expect(egg.buyEgg(1, "")).to.be.revertedWith("Invalid egg");
        });
    });
});
