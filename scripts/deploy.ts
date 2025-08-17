
import { ethers } from "hardhat";
import { run } from "hardhat";

async function main() {
    const Auction = await ethers.getContractFactory("Auction");
    const auction = await Auction.deploy();
    await auction.waitForDeployment();
    const contractAddress = await auction.getAddress();
    console.log("Auction contract deployed to:", contractAddress);

    if (process.env.VERIFY == "true") {
        const deploymentBlockNumber = await ethers.provider.getBlockNumber();
        const targetBlockNumber = deploymentBlockNumber + 5;

        console.log("Waiting for 5 block confirmations before verification...");
        await new Promise((resolve) => {
            ethers.provider.on("block", async (blockNumber) => {
                if (blockNumber >= targetBlockNumber) {
                    ethers.provider.removeAllListeners("block");
                    resolve(null);
                }
                process.stdout.write(".");
            });
        });
        console.log("\nVerifying contract...");

        try {
            await run("verify:verify", {
                address: contractAddress,
                constructorArguments: [],
                force: true,
            });
            console.log("contract verified");
        } catch (e) {
            console.log("contract verification failed:", e);
        }
    }
}

main();
