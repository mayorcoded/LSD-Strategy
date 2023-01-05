import { expect } from "chai";
import { ethers, network } from "hardhat";

import {FixedRateVault, IERC20} from "../typechain";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

const DETH = "0x506c2b850d519065a4005b04b9ceed946a64cb6f";
const savETHPool = "0xb0AD9Da3b4962D94386FdeaE32340a0A8E58f8d1";
const mevAndFeesPool = "0x611beA2dB2BA155C04FE47723D91A3Dc0f52Fbe1";

describe("FixedRateVault", function () {
  let fixedRateVault: FixedRateVault;
  let vaultManager: SignerWithAddress,
    depositor1: SignerWithAddress,
    depositor2: SignerWithAddress,
    depositor3: SignerWithAddress;
  let dETH: IERC20;

  before(async function() {
    [depositor1, depositor2] = await ethers.getSigners();
    dETH = await ethers.getContractAt("IERC20", DETH)

    const giantPoolVaultFactory = await ethers.getContractFactory("FixedRateVault", vaultManager);
    fixedRateVault = await giantPoolVaultFactory.deploy( DETH, savETHPool, mevAndFeesPool);
  });

  it("Should deposit ETH into the pool", async function () {
    const amount = ethers.utils.parseUnits("5", 18);
    await fixedRateVault.deposit(amount, {value: amount});
  });
});
