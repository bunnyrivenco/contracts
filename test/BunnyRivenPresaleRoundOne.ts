import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { BigNumber } from "ethers";

describe("BunnyRivenPreSaleRoundOne", function () {
    const toBN = (number: number, decimal = 18) =>
        BigNumber.from(+number).mul(BigNumber.from(10).pow(decimal));
    const sig =
        "0x1556a70d76cc452ae54e83bb167a9041f0d062d000fa0dcb42593f77c544f6471643d14dbd6a6edc658f4b16699a585181a08dba4f6d16a9273e0e2cbed622da1b";
    const usdtPerToken = ethers.utils.parseEther("0.01");
    const ticket = "ticket";
    // We define a fixture to reuse the same setup in every test.
    // We use loadFixture to run this setup once, snapshot that state,
    // and reset Hardhat Network to that snapshot in every test.
    async function deployPreSaleFixture() {
        const ONE_DAY_IN_SECS = 365 * 24 * 60 * 60;
        const startTime = (await time.latest()) + ONE_DAY_IN_SECS;
        const endTime = startTime + ONE_DAY_IN_SECS;

        // Contracts are deployed using the first signer/account by default
        const [owner, otherAccount] = await ethers.getSigners();

        const BunnyRiven = await ethers.getContractFactory("BunnyRiven");
        const bunnyRiven = await BunnyRiven.deploy();

        const PreSale = await ethers.getContractFactory(
            "BunnyRivenPreSaleRoundOne"
        );
        const preSale = await PreSale.deploy(
            bunnyRiven.address,
            bunnyRiven.address,
            bunnyRiven.address,
            usdtPerToken,
            ethers.utils.parseEther("1000"),
            startTime,
            1
        );

        return { preSale, bunnyRiven, owner, otherAccount, startTime, endTime };
    }

    describe("Deployment", function () {
        it("Should set the right owner", async function () {
            const { preSale, owner } = await loadFixture(deployPreSaleFixture);

            expect(await preSale.owner()).to.equal(owner.address);
        });
    });

    describe("Validations", function () {
        it("Should revert with the right error if buy too soon", async function () {
            const { preSale } = await loadFixture(deployPreSaleFixture);

            await expect(
                preSale.buyTokenByBnb(ticket, sig, { value: 1 })
            ).to.be.revertedWith("PreSale hasn't started yet");
        });

        // it("Shouldn't fail if the unlockTime has arrived and the user calls it", async function () {
        //     const { preSale, startTime } = await loadFixture(
        //         deployPreSaleFixture
        //     );

        //     // Transactions are sent using the first signer by default
        //     await time.increaseTo(startTime);

        //     await expect(
        //         preSale.buyTokenByBnb(ticket, sig, { value: 1 })
        //     ).to.be.revertedWith("Invalid signature");
        // });

        it("Should revert with the right error if buy too late", async function () {
            const { preSale, endTime } = await loadFixture(
                deployPreSaleFixture
            );

            await time.increaseTo(endTime);

            await expect(
                preSale.buyTokenByBnb(ticket, sig, { value: 1 })
            ).to.be.revertedWith("PreSale has ended");
        });

        it("Should revert with the right error when owner has not set permissions", async function () {
            const { preSale } = await loadFixture(deployPreSaleFixture);

            await expect(preSale.withdrawBunnyRiven(1)).to.be.revertedWith(
                "You can't withdraw yet"
            );
        });

        it("Should revert with the right error when agency withdraw with wrong sig", async function () {
            const { preSale } = await loadFixture(deployPreSaleFixture);

            await expect(preSale.withdraw(1, "secret", sig)).to.be.revertedWith(
                "Invalid signature"
            );
        });
    });

    describe("Buy token", function () {
        it("Should transfer bnb when buy token and increase balance token", async function () {
            const { preSale, owner, startTime } = await loadFixture(
                deployPreSaleFixture
            );
            await time.increaseTo(startTime);
            const value = "0.05";
            await expect(
                preSale.buyTokenByBnb(ticket, sig, {
                    value: ethers.utils.parseEther(value),
                })
            ).to.changeEtherBalances(
                [owner, preSale],
                [
                    ethers.utils.parseEther("-" + value),
                    ethers.utils.parseEther(value),
                ]
            );

            await expect(
                preSale.withdrawBnbOwner(ethers.utils.parseEther(value))
            ).to.changeEtherBalances(
                [owner, preSale],
                [
                    ethers.utils.parseEther(value),
                    ethers.utils.parseEther("-" + value),
                ]
            );
        });

        it("Should transfer usdt when buy pre sale using usdt", async function () {
            const { preSale, bunnyRiven, owner, startTime } = await loadFixture(
                deployPreSaleFixture
            );
            await time.increaseTo(startTime);

            await (
                await bunnyRiven.approve(preSale.address, toBN(1000000))
            ).wait();

            const value = "1";
            await expect(
                preSale.buyTokenByUsdt(
                    ethers.utils.parseEther(value),
                    ticket,
                    sig
                )
            ).to.changeTokenBalances(
                bunnyRiven,
                [owner, preSale],
                [
                    ethers.utils.parseEther("-" + value),
                    ethers.utils.parseEther(value),
                ]
            );

            await expect(
                preSale.buyTokenByUsdt(
                    ethers.utils.parseEther("1000"),
                    ticket,
                    sig
                )
            ).to.be.revertedWith("Maximum value of ticket");

            expect(await preSale.balanceOf(owner.address)).to.equal(
                ethers.utils.parseEther("0.5")
            );

            expect(
                await preSale.usdtNeedToBuyRemainOf(owner.address, ticket)
            ).to.equal(ethers.utils.parseEther("199"));
        });
    });
});
