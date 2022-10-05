const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("INO", function () {
  it("Init", async function () {
    const [owner, addr1, addr2] = await ethers.getSigners();
    
    const MembershipNFT = await ethers.getContractFactory("MembershipNFT");
    const LiveTrade = await ethers.getContractFactory("LiveTrade");
    const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    const HesicNFT = await ethers.getContractFactory("HesicNFT");
    const LiveTradeINO = await ethers.getContractFactory("LiveTradeINO");

    const instanceStandardMembershipNFT = await MembershipNFT.deploy("StandardMembershipNFT", "STM");
    const instanceDeluxeMembershipNFT = await MembershipNFT.deploy("DeluxeMembershipNFT", "DEM");
    const instanceEliteMembershipNFT = await MembershipNFT.deploy("EliteMembershipNFT", "ELM");
    const instanceGoldMembershipNFT = await MembershipNFT.deploy("GoldMembershipNFT", "GOM");
    const instancePlatinumMembershipNFT = await MembershipNFT.deploy("PlatinumMembershipNFT", "PLM");
    const instanceDiamondMembershipNFT = await MembershipNFT.deploy("DiamondMembershipNFT", "DIM");

    // Mint MembershipNFT
    await instanceStandardMembershipNFT.safeMint(owner.address);
    await instanceDeluxeMembershipNFT.safeMint(owner.address);
    await instanceEliteMembershipNFT.safeMint(owner.address);
    await instanceGoldMembershipNFT.safeMint(owner.address);
    await instancePlatinumMembershipNFT.safeMint(owner.address);
    await instanceDiamondMembershipNFT.safeMint(owner.address);

    const instanceLiveTrade = await LiveTrade.deploy();
    const instanceBinanceCoin = await BinanceCoin.deploy();
    const instanceHesicNFT = await HesicNFT.deploy();
    const addressLiveTrade =  instanceLiveTrade.address;
    const addressBinanceCoin = instanceBinanceCoin.address;
    const addressHesicNFT = instanceHesicNFT.address;

    const devWallet = addr1.address;
    const instanceLiveTradeINO = await LiveTradeINO.deploy();

    // approve LiveTrade and BinanceCoin to transfer ownership of LiveTradeINO
    await instanceLiveTrade.approve(instanceLiveTradeINO.address, ethers.constants.MaxUint256);
    await instanceBinanceCoin.approve(instanceLiveTradeINO.address, ethers.constants.MaxUint256);
    await instanceLiveTrade.approve(owner.address, ethers.constants.MaxUint256);
    await instanceBinanceCoin.approve(owner.address, ethers.constants.MaxUint256);
    // approve MembershipNFT transfer ownership of LiveTradeINO
    await instanceStandardMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    await instanceDeluxeMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    await instanceEliteMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    await instanceGoldMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    await instancePlatinumMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    await instanceDiamondMembershipNFT.approve(instanceLiveTradeINO.address, 0);
    
    // console.log("Address owner:", owner.address);
    // console.log("Address instanceLiveTradeINO:", instanceLiveTradeINO.address);

    // console.log("ownerOf MembershipNFT", await instanceStandardMembershipNFT.ownerOf(0));
    // console.log("getApproved MembershipNFT", await instanceStandardMembershipNFT.getApproved(0));

    // mint token to owner
    await instanceLiveTrade.mint(owner.address, '10000000000000000000000');
    await instanceBinanceCoin.mint(owner.address, '10000000000000000000000');
    // setupAddress
    await instanceLiveTradeINO.setupAddress(addressLiveTrade, addressBinanceCoin, addressHesicNFT, devWallet);
    //setLevelStake
    const maxAmountBuyNft = [1, 1, 2, 3, 4, 5];
    const addressNftStake = [instanceStandardMembershipNFT.address, instanceDeluxeMembershipNFT.address, instanceEliteMembershipNFT.address, instanceGoldMembershipNFT.address, instancePlatinumMembershipNFT.address, instanceDiamondMembershipNFT.address];
    await instanceLiveTradeINO.setLevelStake(maxAmountBuyNft, addressNftStake);

    // for (let i = 0; i < maxAmountBuyNft.length; i++) {
    //   console.log(await instanceLiveTradeINO.listLevelBuyNft(i));
    // }
    
    // setUpINO
    await instanceHesicNFT.superMint(instanceLiveTradeINO.address, 5); // Mint NFT for LiveTradeINO
    await instanceLiveTradeINO.setUpINO(0, 0, 5000, 100,3,2);
    console.log("limitAmountBuyMembership", await instanceLiveTradeINO.limitAmountBuyMembership());

    console.log("totalNftSupply", await instanceLiveTradeINO.totalNftSupply());

    // registerBuyForFCFS
    await instanceLiveTradeINO.registerBuyForFCFS();
    console.log("amountStakingFCFS", await instanceLiveTrade.balanceOf(instanceLiveTradeINO.address));

    // buyNftOfMembership
    await instanceLiveTradeINO.buyNftOfFCFS();
    // await instanceLiveTradeINO.buyNftOfFCFS();

    console.log("Hexis claimed", await instanceHesicNFT.balanceOf(owner.address));

    // registerBuyForMembership
    // await instanceLiveTradeINO.registerBuyForMembership(2);
    // console.log("Membership", await instanceEliteMembershipNFT.ownerOf(0));
    
    // buyNftOfMembership
    // await instanceLiveTradeINO.buyNftOfMembership(1);
    // await instanceLiveTradeINO.buyNftOfMembership(1);
    // console.log("Membership", await instanceEliteMembershipNFT.ownerOf(0));
    // console.log("Hexis claimed", await instanceHesicNFT.balanceOf(owner.address));

    // await instanceLiveTradeINO.buyNftOfFCFS();
    // console.log("Hexis claimed", await instanceHesicNFT.balanceOf(owner.address));

    // withDrawNftForUser
    // await instanceLiveTradeINO.withDrawNftForUser();
    // console.log("Membership", await instanceEliteMembershipNFT.ownerOf(0));

    // withDrawNftForOwner Hexis
    console.log("Before withdraw Hexis", await instanceHesicNFT.balanceOf(owner.address));
    await instanceLiveTradeINO.withDrawNftForOwner();
    console.log("After withdraw Hexis", await instanceHesicNFT.balanceOf(owner.address));

  });
});
