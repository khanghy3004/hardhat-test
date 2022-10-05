const { ethers } = require("hardhat");

describe("IDO", function () {
    it("PiPrivateSaleVesting", async function () {
        const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
        const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
        const PiPrivateSaleVesting = await ethers.getContractFactory("PiPrivateSaleVesting");

        const instanceBinanceCoin = await BinanceCoin.deploy();
        const instancePiPrivateSaleVesting = await PiPrivateSaleVesting.deploy(instanceBinanceCoin.address, addr1.address, 1664941200);

        // mint
        await instanceBinanceCoin.mint(instancePiPrivateSaleVesting.address, ethers.utils.parseEther("37500000"));

        // vest tge
        await instancePiPrivateSaleVesting.connect(addr1).release();
        console.log("vest tge", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr1.address)));

        await ethers.provider.send("hardhat_mine", ["0x" + (30 * 86400).toString(16)]);

        // vest
        await instancePiPrivateSaleVesting.connect(addr1).release();
        console.log("vest tge", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr1.address)));

        await ethers.provider.send("hardhat_mine", ["0x" + (30*30 * 86400).toString(16)]);

        // vest
        await instancePiPrivateSaleVesting.connect(addr1).release();
        console.log("vest tge", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr1.address)));

        
    })
    // it("PiNFT", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const PiBridgeTessaractNFTs = await ethers.getContractFactory("PiBridgeTessaractNFTs");

    //     const instancePiBridgeTessaractNFTs = await PiBridgeTessaractNFTs.deploy();

    //     // set start time
    //     await instancePiBridgeTessaractNFTs.setStartTime(1620000000);
    //     // set whitelist
    //     // await instancePiBridgeTessaractNFTs.setupWhitelistRole([addr1.address], true);
    //     // await instancePiBridgeTessaractNFTs.setupMinterRole([addr1.address], true);
    //     // mint
    //     await instancePiBridgeTessaractNFTs.connect(addr1).safeMintWhiteList();

    // })
    // it("RunTogetherPoolStore", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const RunTogetherPoolProposal = await ethers.getContractFactory("RunTogetherPoolProposal");
    //     const RunTogetherPoolStore = await ethers.getContractFactory("RunTogetherPoolStore");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceTokenAFC = await TokenAFC.deploy();
    //     const instanceRunTogetherPoolProposal = await RunTogetherPoolProposal.deploy(instanceTokenAFC.address, instanceBinanceCoin.address, addr2.address, addr1.address);
    //     const instanceRunTogetherPoolStore = await RunTogetherPoolStore.deploy(instanceRunTogetherPoolProposal.address, addr2.address);
        
    //     await instanceRunTogetherPoolProposal.setRunTogetherPoolStore(instanceRunTogetherPoolStore.address);
        

    //     // mint
    //     await instanceBinanceCoin.mint(instanceRunTogetherPoolProposal.address, ethers.utils.parseEther("10000"));
    //     await instanceTokenAFC.mint(owner.address, ethers.utils.parseEther("10000"));
    //     await instanceTokenAFC.mint(addr2.address, ethers.utils.parseEther("10000000"));
    //     await instanceTokenAFC.mint(addr3.address, ethers.utils.parseEther("10000000"));
    //     await instanceTokenAFC.mint(addr4.address, ethers.utils.parseEther("10000000"));
    //     await instanceTokenAFC.mint(instanceRunTogetherPoolStore.address, ethers.utils.parseEther("1000000"));


    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherPoolProposal.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.approve(instanceRunTogetherPoolProposal.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.connect(addr2).approve(instanceRunTogetherPoolProposal.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.connect(addr3).approve(instanceRunTogetherPoolProposal.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.connect(addr4).approve(instanceRunTogetherPoolProposal.address, ethers.constants.MaxUint256);

    //     await instanceBinanceCoin.approve(instanceRunTogetherPoolStore.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.approve(instanceRunTogetherPoolStore.address, ethers.constants.MaxUint256);

    //     // unpause
    //     await instanceRunTogetherPoolProposal.setPauseContract(false);
    //     await instanceRunTogetherPoolStore.setPauseContract(false);
        
        
    //     // set time pool
    //     await instanceRunTogetherPoolProposal.setStartEndTimePool(1661475600, 2693076830);
    //     // set block pool
    //     await instanceRunTogetherPoolProposal.setStartEndBlockPool(0, 10512000);


    //     // add pool 0
    //     await instanceRunTogetherPoolStore.addPool(instanceTokenAFC.address,instanceTokenAFC.address);

    //     // deposit 0
    //     await instanceRunTogetherPoolProposal.deposit(ethers.utils.parseEther("1000"), owner.address);
    //     await instanceRunTogetherPoolProposal.connect(addr2).deposit(ethers.utils.parseEther("1000"), addr2.address);
    //     await instanceRunTogetherPoolProposal.connect(addr3).deposit(ethers.utils.parseEther("1000"), addr3.address);

    //     await instanceRunTogetherPoolProposal.withdraw(ethers.utils.parseEther("500"), owner.address);


    //     console.log("Block", await ethers.provider.getBlockNumber());
    //     await ethers.provider.send("hardhat_mine", ["0x" + (50 * 86400).toString(16)]);
    //     console.log("Block", await ethers.provider.getBlockNumber());


    //     // snapshot 0
    //     await instanceRunTogetherPoolStore.snapshot(0, ethers.utils.parseEther("2000"));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, owner.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr2.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr3.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr4.address)));

    //     // add pool 1
    //     await instanceRunTogetherPoolStore.addPool(instanceTokenAFC.address,instanceTokenAFC.address);
    //     // deposit 1
    //     await instanceRunTogetherPoolProposal.deposit(ethers.utils.parseEther("1000"), owner.address);
    //     await instanceRunTogetherPoolProposal.connect(addr4).deposit(ethers.utils.parseEther("1000"), addr4.address);
    //     // withdraw 1
    //     await instanceRunTogetherPoolProposal.connect(addr2).withdraw(ethers.utils.parseEther("1000"), addr2.address);
    //     // snapshot 1
    //     await instanceRunTogetherPoolStore.snapshot(1, ethers.utils.parseEther("2000"));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, owner.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr2.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr3.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr4.address)));


    //     // add pool 2
    //     await instanceRunTogetherPoolStore.addPool(instanceTokenAFC.address,instanceTokenAFC.address);
    //     await instanceRunTogetherPoolProposal.connect(addr2).deposit(ethers.utils.parseEther("1000"), addr2.address);
    //     // snapshot 2
    //     await instanceRunTogetherPoolStore.snapshot(2, ethers.utils.parseEther("2000"));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, owner.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr2.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr3.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr4.address)));


    //     // add pool 3
    //     await instanceRunTogetherPoolStore.addPool(instanceTokenAFC.address,instanceTokenAFC.address);
    //     await instanceRunTogetherPoolProposal.connect(addr4).deposit(ethers.utils.parseEther("1000"), addr4.address);
    //     // snapshot 3
    //     await instanceRunTogetherPoolStore.snapshot(3, ethers.utils.parseEther("2000"));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, owner.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr2.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr3.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr4.address)));

    //     // show history
    //     console.log("history");
    //     //  pendingReward
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, owner.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr2.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr3.address)));
    //     console.log("pendingReward 0", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(0, addr4.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, owner.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr2.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr3.address)));
    //     console.log("pendingReward 1", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(1, addr4.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, owner.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr2.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr3.address)));
    //     console.log("pendingReward 2", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(2, addr4.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, owner.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr2.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr3.address)));
    //     console.log("pendingReward 3", ethers.utils.formatEther(await instanceRunTogetherPoolStore.pendingReward(3, addr4.address)));

    //     // withdraw 0
    //     await instanceRunTogetherPoolStore.withdraw(0);
    //     // withdraw 1
    //     await instanceRunTogetherPoolStore.withdraw(1);
    //     // withdraw 2
    //     await instanceRunTogetherPoolStore.withdraw(2);
    //     // withdraw 3
    //     await instanceRunTogetherPoolStore.withdraw(3);

    //     // withdraw all
    //     await instanceRunTogetherPoolStore.connect(addr4).withdrawAll();

    //     console.log(ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(addr1.address)));
    // })
    // it("RunTogetherFarm", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const ChefRUNToken = await ethers.getContractFactory("ChefRUNToken");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceTokenAFC = await TokenAFC.deploy();
    //     const instanceChefRUNToken = await ChefRUNToken.deploy(instanceBinanceCoin.address, addr1.address, addr2.address, addr3.address, '47564687970000000', 0, 31536000);

    //     // mint
    //     await instanceBinanceCoin.mint(addr3.address, ethers.utils.parseEther("1500000"));
    //     await instanceTokenAFC.mint(owner.address, ethers.utils.parseEther("10000"));
    //     await instanceTokenAFC.mint(addr4.address, ethers.utils.parseEther("10000"));


    //     // approve
    //     await instanceBinanceCoin.connect(addr3).approve(instanceChefRUNToken.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.approve(instanceChefRUNToken.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.connect(addr4).approve(instanceChefRUNToken.address, ethers.constants.MaxUint256);


    //     // add lp
    //     await instanceChefRUNToken.add(100, instanceTokenAFC.address, 50, true);

    //     // deposit
    //     await instanceChefRUNToken.deposit(0, ethers.utils.parseEther("100"));
    //     // await instanceChefRUNToken.connect(addr4).deposit(0, ethers.utils.parseEther("200"));

    //     console.log("Block", await ethers.provider.getBlockNumber());
    //     await ethers.provider.send("hardhat_mine", ["0x" + (365*86400).toString(16)]);
    //     console.log("Block", await ethers.provider.getBlockNumber());

    //     // harvest
    //     // await instanceChefRUNToken.harvest(0);

    //     // withdraw
    //     // await instanceChefRUNToken.withdraw(0, ethers.utils.parseEther("100"));

    //     // console.log(ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceChefRUNToken.pendingRUNToken(0, owner.address))/1500000);
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(addr2.address)));


    // })
    // it("RunTogetherMarketplaceAdmin", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const RunTogetherBoxNFT = await ethers.getContractFactory("RunTogetherBoxNFT");
    //     const RunTogetherMarketplaceAdmin = await ethers.getContractFactory("RunTogetherMarketplaceAdmin");
    //     const RunTogetherMarketplace = await ethers.getContractFactory("RunTogetherMarketplace");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceRunTogetherBoxNFT = await RunTogetherBoxNFT.deploy();
    //     const instanceRunTogetherMarketplaceAdmin = await RunTogetherMarketplaceAdmin.deploy(instanceRunTogetherBoxNFT.address, instanceBinanceCoin.address, addr1.address, addr2.address, 200, true);
    //     const instanceRunTogetherMarketplace = await RunTogetherMarketplace.deploy(instanceRunTogetherBoxNFT.address, instanceRunTogetherMarketplaceAdmin.address, addr1.address, 30, [instanceBinanceCoin.address], true);

    //     // mint
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000000"));
    //     await instanceBinanceCoin.mint(addr4.address, ethers.utils.parseEther("1000000"));

    //     await instanceRunTogetherBoxNFT.connect(addr1).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 1);
    //     await instanceRunTogetherBoxNFT.connect(addr1).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 2);
    //     await instanceRunTogetherBoxNFT.connect(addr1).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 3);
    //     await instanceRunTogetherBoxNFT.connect(addr1).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 4);
    //     console.log("ok1");
    //     await instanceRunTogetherBoxNFT.connect(addr2).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 1);
    //     await instanceRunTogetherBoxNFT.connect(addr2).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 2);
    //     await instanceRunTogetherBoxNFT.connect(addr2).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 3);
    //     await instanceRunTogetherBoxNFT.connect(addr2).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 4);
    //     console.log("ok2");

    //     await instanceRunTogetherBoxNFT.connect(addr3).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 1);
    //     await instanceRunTogetherBoxNFT.connect(addr3).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 2);
    //     await instanceRunTogetherBoxNFT.connect(addr3).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 3);
    //     await instanceRunTogetherBoxNFT.connect(addr3).multiMint(instanceRunTogetherMarketplaceAdmin.address, 100, 4);
    //     console.log("ok2");

    //     console.log("Total nft in contract: " + await instanceRunTogetherBoxNFT.balanceOf(instanceRunTogetherMarketplaceAdmin.address));

    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherMarketplaceAdmin.address, ethers.constants.MaxUint256);
    //     await instanceBinanceCoin.connect(addr4).approve(instanceRunTogetherMarketplaceAdmin.address, ethers.constants.MaxUint256);
    //     await instanceRunTogetherBoxNFT.setApprovalForAll(instanceRunTogetherMarketplaceAdmin.address, true);
    //     await instanceRunTogetherBoxNFT.connect(addr4).setApprovalForAll(instanceRunTogetherMarketplaceAdmin.address, true);

    //     console.log("ok3");

    //     // add seller
    //     await instanceRunTogetherMarketplaceAdmin.addSellerList([owner.address]);

    //     // setPercentSaleOffMembership
    //     await instanceRunTogetherMarketplaceAdmin.setPercentSaleOffKho([5,25,125,625], [30,50,70,100]);

    //     // update price
    //     await instanceRunTogetherMarketplaceAdmin.updateBoxPrice([1, 2, 3, 4], [ethers.utils.parseEther("15"), ethers.utils.parseEther("50"), ethers.utils.parseEther("100"), ethers.utils.parseEther("200")], 0, 600);

    //     //resetNft
    //     // await instanceRunTogetherMarketplaceAdmin.resetNft([1,2,3,4]);

    //     await instanceRunTogetherMarketplaceAdmin.updateBoxPrice([1, 2, 3, 4], [ethers.utils.parseEther("15"), ethers.utils.parseEther("50"), ethers.utils.parseEther("100"), ethers.utils.parseEther("200")], 600, 1200);
    //     // await instanceRunTogetherMarketplaceAdmin.updateBoxPrice([1, 2, 3, 4], [ethers.utils.parseEther("15"), ethers.utils.parseEther("50"), ethers.utils.parseEther("100"), ethers.utils.parseEther("200")], 1600, 2400);



    //     //setMaxNftInTransfer
    //     await instanceRunTogetherMarketplaceAdmin.setMaxNftInTransfer([1,2,3,4], [50,50,50,50]);
    //     console.log("ok4");


    //     // buy
    //     await instanceRunTogetherMarketplaceAdmin.buyItem([1,2,3,4]);
    //     await instanceRunTogetherMarketplaceAdmin.connect(addr4).buyItem([50,49,0,53]);
    //     console.log("ok5");

    //     // claim
    //     await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.claimItem();
    //     // // await instanceRunTogetherMarketplaceAdmin.claimItem();

    //     // // await instanceRunTogetherMarketplaceAdmin.claimItem();

    //     // await instanceRunTogetherMarketplaceAdmin.connect(addr4).claimItem();
    //     // await instanceRunTogetherMarketplaceAdmin.connect(addr4).claimItem();

    //     // await instanceRunTogetherMarketplaceAdmin.connect(addr4).claimItem();

    //     // console.log("listTokenId", await instanceRunTogetherMarketplaceAdmin.listTokenId(owner.address, 0));

    //     console.log("tokenIdToAddressMap", await instanceRunTogetherMarketplaceAdmin.tokenIdToAddressMap(899));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.getBoxTypeRunTogether(899));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.tokenIdToAddressMap(999));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.getBoxTypeRunTogether(999));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.tokenIdToAddressMap(1098));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.getBoxTypeRunTogether(1098));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.tokenIdToAddressMap(1197));
    //     // console.log(await instanceRunTogetherMarketplaceAdmin.getBoxTypeRunTogether(1197));


    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherMarketplace.address, ethers.constants.MaxUint256);
    //     await instanceBinanceCoin.connect(addr4).approve(instanceRunTogetherMarketplace.address, ethers.constants.MaxUint256);
    //     await instanceRunTogetherBoxNFT.setApprovalForAll(instanceRunTogetherMarketplace.address, true);
    //     await instanceRunTogetherBoxNFT.connect(addr4).setApprovalForAll(instanceRunTogetherMarketplace.address, true);

    //     // sell nft to market
    //     instanceRunTogetherMarketplace.sellItem(instanceRunTogetherBoxNFT.address, 899, ethers.utils.parseEther("1"), instanceBinanceCoin.address);

    //     // buy nft from market
    //     await instanceRunTogetherMarketplace.connect(addr4).buyItem(0);

    //     console.log("tokenIdToAddressMap", await instanceRunTogetherMarketplaceAdmin.tokenIdToAddressMap(899));


    //     console.log(await instanceRunTogetherBoxNFT.balanceOf(owner.address));
    //     console.log(await instanceRunTogetherBoxNFT.balanceOf(addr4.address));
    //     console.log(await instanceBinanceCoin.balanceOf(addr1.address));
    //     console.log(await instanceBinanceCoin.balanceOf(addr2.address));


    // })

    // it("RunTogetherPool", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const RunTogetherPool = await ethers.getContractFactory("RunTogetherPoolProposal");
    //     const RunTogetherPool2 = await ethers.getContractFactory("RunTogetherPool2");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceTokenAFC = await TokenAFC.deploy();
    //     const instanceRunTogetherPool = await RunTogetherPool.deploy(instanceTokenAFC.address, instanceBinanceCoin.address, addr2.address, owner.address);
    //     const instanceRunTogetherPool2 = await RunTogetherPool2.deploy(instanceRunTogetherPool.address);

    //     // mint
    //     await instanceBinanceCoin.mint(instanceRunTogetherPool.address, ethers.utils.parseEther("10000"));
    //     await instanceTokenAFC.mint(owner.address, ethers.utils.parseEther("10000"));

    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherPool.address, ethers.constants.MaxUint256);
    //     await instanceTokenAFC.approve(instanceRunTogetherPool.address, ethers.constants.MaxUint256);

    //     // unpause
    //     await instanceRunTogetherPool.setPauseContract(false);
    //     // set time pool
    //     await instanceRunTogetherPool.setStartEndTimePool(1661475600, 2693076830);
    //     // set block pool
    //     await instanceRunTogetherPool.setStartEndBlockPool(0, 10512000);
    //     // setFeeWallet
    //     await instanceRunTogetherPool.setFeeWallet(addr1.address);
    //     // set compound
    //     await instanceRunTogetherPool.setCompound(false);
    //     console.log("ok1");
    //     // deposit
    //     await instanceRunTogetherPool.deposit(ethers.utils.parseEther("1000"), '0xA6912ed0CB1700c0fa7200Dfe26e90dd2aE2364a', 27, "0x5611c8761908799a292e76a1bfeeaf16cbfe6278440078bc1df34931870df59b", "0x2f94563d00d5b88e128cc42d2eb9d7a9272798cc3c53466559fabe24f383d46e");


    //     // console.log("Block", await ethers.provider.getBlockNumber());
    //     // await ethers.provider.send("hardhat_mine", ["0x" + (90).toString(16)]);
    //     // console.log("Block", await ethers.provider.getBlockNumber());

    //     // deposit
    //     // await instanceRunTogetherPool.deposit(ethers.utils.parseEther("5000"));

    //     console.log("Block", await ethers.provider.getBlockNumber());
    //     await ethers.provider.send("hardhat_mine", ["0x" + (366*86400).toString(16)]);
    //     console.log("Block", await ethers.provider.getBlockNumber());

    //     // // deposit
    //     // await instanceRunTogetherPool.deposit(ethers.utils.parseEther("1000"));

    //     // await ethers.provider.send('evm_increaseTime', [30*24*60*60]);
    //     // await network.provider.send("evm_mine");

    //     // await ethers.provider.send("hardhat_mine", ["0x" + (100).toString(16)]);

    //     // withdraw
    //     // await instanceRunTogetherPool2.superWithdraw(ethers.utils.parseEther("1000"));

    //     // console.log("Block", await ethers.provider.getBlockNumber());
    //     // await ethers.provider.send("hardhat_mine", ["0x" + (30*86400).toString(16)]);
    //     // console.log("Block", await ethers.provider.getBlockNumber());

    //     await instanceRunTogetherPool.withdraw(ethers.utils.parseEther("0"), '0xA6912ed0CB1700c0fa7200Dfe26e90dd2aE2364a', 27, "0x5611c8761908799a292e76a1bfeeaf16cbfe6278440078bc1df34931870df59b", "0x2f94563d00d5b88e128cc42d2eb9d7a9272798cc3c53466559fabe24f383d46e");

    //     console.log(ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(owner.address)));
    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(addr1.address)));
    // })
    // it("RunTogetherMarketplace", async function () {
    //     const [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const RunTogetherBoxNFT = await ethers.getContractFactory("RunTogetherBoxNFT");
    //     const RunTogetherMarketplace = await ethers.getContractFactory("RunTogetherMarketplace");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceRunTogetherBoxNFT = await RunTogetherBoxNFT.deploy();
    //     const instanceRunTogetherMarketplace = await RunTogetherMarketplace.deploy(instanceRunTogetherBoxNFT.address, addr1.address, addr2.address, addr3.address, 200, 50, [instanceBinanceCoin.address], true);

    //     // mint
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000"));
    //     await instanceBinanceCoin.mint(addr4.address, ethers.utils.parseEther("1000"));

    //     await instanceRunTogetherBoxNFT.safeMint(owner.address);
    //     await instanceRunTogetherBoxNFT.safeMint(owner.address);
    //     await instanceRunTogetherBoxNFT.safeMint(owner.address);

    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherMarketplace.address, ethers.constants.MaxUint256);
    //     await instanceBinanceCoin.connect(addr4).approve(instanceRunTogetherMarketplace.address, ethers.constants.MaxUint256);
    //     await instanceRunTogetherBoxNFT.setApprovalForAll(instanceRunTogetherMarketplace.address, true);
    //     await instanceRunTogetherBoxNFT.connect(addr4).setApprovalForAll(instanceRunTogetherMarketplace.address, true);

    //     // add seller
    //     await instanceRunTogetherMarketplace.addSellerList([owner.address]);

    //     console.log("nft balance: ", await instanceRunTogetherBoxNFT.balanceOf(owner.address));

    //     // sell admin
    //     await instanceRunTogetherMarketplace.sellItemAdmin(instanceRunTogetherBoxNFT.address, [1,2], ethers.utils.parseEther("100"), instanceBinanceCoin.address);
    //     // sell user
    //     await instanceRunTogetherMarketplace.sellItemUser(instanceRunTogetherBoxNFT.address, 0, ethers.utils.parseEther("100"), instanceBinanceCoin.address);

    //     // buy
    //     await instanceRunTogetherMarketplace.connect(addr4).buyItem([0,1]);

    //     // check
    //     console.log("seller", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));
    //     console.log("buyer", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr4.address)));
    //     console.log("market fee", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr1.address)));
    //     console.log("pool reward", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr2.address)));
    //     console.log("pool admin", ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(addr3.address)));

    //     console.log("buyer nft", await instanceRunTogetherBoxNFT.balanceOf(addr4.address));

    //     await instanceRunTogetherMarketplace.connect(addr4).sellItemUser(instanceRunTogetherBoxNFT.address, 2, ethers.utils.parseEther("99"), instanceBinanceCoin.address);
    //     await instanceRunTogetherMarketplace.buyItem([3]);

    //     console.log("origin", await instanceRunTogetherMarketplace.getListBuyerAdminOrigin(2));
    //     console.log("saleItems", await instanceRunTogetherMarketplace.saleItems(3));


    // })
    // it("RunTogetherMigration", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const RunTogetherEcoVesting = await ethers.getContractFactory("RunTogetherEcoVesting");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceRunTogetherEcoVesting = await RunTogetherEcoVesting.deploy(instanceBinanceCoin.address, owner.address);

    //     // mint
    //     await instanceBinanceCoin.mint(instanceRunTogetherEcoVesting.address, ethers.utils.parseEther("77500000"));

    //     // vesting
    //     console.log(1);
    //     await hre.ethers.provider.send('evm_increaseTime', [35 * 30 * 24 * 60 * 60]); // increase time to 30 days
    //     await instanceRunTogetherEcoVesting.release();

    //     console.log(ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));

    //     // vesting
    //     console.log(2);
    //     await hre.ethers.provider.send('evm_increaseTime', [1 * 30 * 24 * 60 * 60]); // increase time to 30 days
    //     await instanceRunTogetherEcoVesting.release();

    //     // check
    //     console.log(ethers.utils.formatEther(await instanceBinanceCoin.balanceOf(owner.address)));
    // })
    // it("RunTogetherMigration", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const RunTogetherMigration = await ethers.getContractFactory("RunTogetherMigration");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceTokenAFC = await TokenAFC.deploy();
    //     const instanceRunTogetherMigration = await RunTogetherMigration.deploy(instanceBinanceCoin.address, instanceTokenAFC.address, owner.address);

    //     // mint
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000"));
    //     await instanceTokenAFC.mint(instanceRunTogetherMigration.address, ethers.utils.parseEther("1000"));

    //     // approve
    //     await instanceBinanceCoin.approve(instanceRunTogetherMigration.address, ethers.constants.MaxUint256);

    //     // migrate
    //     await instanceRunTogetherMigration.swap();
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000"));
    //     await instanceTokenAFC.mint(instanceRunTogetherMigration.address, ethers.utils.parseEther("1000"));

    //     await instanceRunTogetherMigration.swap();

    //     await instanceRunTogetherMigration.emergencyWithdrawToken();

    //     // check
    //     console.log(await instanceBinanceCoin.balanceOf(owner.address));
    //     console.log(await instanceTokenAFC.balanceOf(owner.address));
    // })
    // it("FootEarnBamiINO", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const CreateNFTBronze = await ethers.getContractFactory("CreateNFTBronze");
    //     const CreateNFTSilver = await ethers.getContractFactory("CreateNFTSilver");
    //     const CreateNFTGold = await ethers.getContractFactory("CreateNFTGold");
    //     const FootEarnBamiINO = await ethers.getContractFactory("FootEarnBamiINO");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceCreateNFTBronze = await CreateNFTBronze.deploy();
    //     const instanceCreateNFTSilver = await CreateNFTSilver.deploy();
    //     const instanceCreateNFTGold = await CreateNFTGold.deploy();
    //     const instanceFootEarnBamiINO = await FootEarnBamiINO.deploy(instanceBinanceCoin.address, [instanceCreateNFTBronze.address, instanceCreateNFTSilver.address, instanceCreateNFTGold.address], [30,30,30], [ethers.utils.parseEther("100"),ethers.utils.parseEther("100"),ethers.utils.parseEther("100")]);

    //     // mint
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000"));
    //     //mint nft
    //     await instanceCreateNFTBronze.safeMint(instanceFootEarnBamiINO.address);
    //     await instanceCreateNFTSilver.safeMint(instanceFootEarnBamiINO.address);
    //     await instanceCreateNFTGold.safeMint(instanceFootEarnBamiINO.address);

    //     console.log("instanceCreateNFTBronze.address: ", instanceCreateNFTBronze.address);
    //     console.log(await instanceCreateNFTBronze.balanceOf(instanceFootEarnBamiINO.address));
    //     // approve
    //     await instanceBinanceCoin.approve(instanceFootEarnBamiINO.address, ethers.constants.MaxUint256);

    //     // buy
    //     await instanceFootEarnBamiINO.buyNft(1);

    //     // claim
    //     await instanceFootEarnBamiINO.claim();



    //     console.log(await instanceBinanceCoin.balanceOf(owner.address));

    // })
    // it("HesmanShop", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const HesmanShop = await ethers.getContractFactory("HesmanShop");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceHesmanShop = await HesmanShop.deploy(instanceBinanceCoin.address);

    //     // mint
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("1000"));

    //     // approve
    //     await instanceBinanceCoin.approve(instanceHesmanShop.address, ethers.constants.MaxUint256);

    //     // setVoucherForSell
    //     await instanceHesmanShop.setVoucherForSell([1], [ethers.utils.parseEther("100")]);
    //     // buy
    //     await instanceHesmanShop.buyVoucher(1);
    //     await instanceHesmanShop.buyVoucher(1);


    //     console.log(await instanceBinanceCoin.balanceOf(owner.address));

    // })
    // it("Pool1", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const LiveTradeMembership = await ethers.getContractFactory("LiveTradeMembership");
    //     const RunTogetherBoxNFT = await ethers.getContractFactory("RunTogetherBoxNFT");
    //     const LTDMarketPlaceRunTogether = await ethers.getContractFactory("LTDMarketPlaceRunTogether");

    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceRunTogetherBoxNFT = await RunTogetherBoxNFT.deploy();
    //     const instanceLiveTradeMembershipDiamond = await LiveTradeMembership.deploy("LiveTradeMembershipDiamond", "LTDDiamond", "");
    //     const instanceLiveTradeMembershipPlatinum = await LiveTradeMembership.deploy("LiveTradeMembershipPlatinum", "LTDPlatinum", "");

    //     const instanceLTDMarketPlaceRunTogether = await LTDMarketPlaceRunTogether.deploy(
    //         instanceRunTogetherBoxNFT.address, 
    //         addr1.address, 
    //         50, 
    //         [instanceBinanceCoin.address], 
    //         [instanceLiveTradeMembershipDiamond.address, instanceLiveTradeMembershipPlatinum.address], 
    //         true
    //     );

    //     // approve
    //     await instanceBinanceCoin.approve(instanceLTDMarketPlaceRunTogether.address, ethers.constants.MaxUint256);
    //     await instanceRunTogetherBoxNFT.setApprovalForAll(instanceLTDMarketPlaceRunTogether.address, true);
    //     // mint RunTogetherBoxNFT
    //     await instanceRunTogetherBoxNFT.safeMint(owner.address);
    //     // mint instanceLiveTradeMembership
    //     await instanceLiveTradeMembershipDiamond.safeMint(owner.address);
    //     await instanceLiveTradeMembershipPlatinum.safeMint(owner.address);
    //     // set percent
    //     await instanceLTDMarketPlaceRunTogether.setPercentSaleOffMembershipNft([60,50]);
    //     // sell
    //     await instanceLTDMarketPlaceRunTogether.addSellerList([owner.address]);
    //     await instanceLTDMarketPlaceRunTogether.sellItem(instanceRunTogetherBoxNFT.address, 0, ethers.utils.parseEther("100"), instanceBinanceCoin.address);
    //     // buy
    //     await instanceLTDMarketPlaceRunTogether.buyItem(0);

    //     console.log(await instanceBinanceCoin.balanceOf(owner.address));

    // });

    // it("Pool1", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const TokenASD = await ethers.getContractFactory("TokenASD");
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const BamiIDO2 = await ethers.getContractFactory("BamiIDO2");
    //     const BamiHesmanIDO = await ethers.getContractFactory("BamiHesmanIDO");

    //     const instanceTokenAFC = await TokenAFC.deploy(); //hesman
    //     const instanceTokenASD = await TokenASD.deploy(); //bami
    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceBamiIDO2 = await BamiIDO2.deploy(addr1.address, addr2.address, instanceTokenAFC.address, instanceTokenASD.address, instanceBinanceCoin.address);
    //     const instanceBamiHesmanIDO = await BamiHesmanIDO.deploy(instanceBamiIDO2.address, instanceBamiIDO2.address, instanceBamiIDO2.address, instanceTokenAFC.address, owner.address);

    //     console.log("Bami1", instanceBamiIDO2.address);
    //     console.log("wallet", owner.address);

    //     //unpause
    //     await instanceBamiIDO2.setPauseContract(false);
    //     await instanceBamiHesmanIDO.setPauseContract(false);
    //     // approve BamiIDO2 to spend tokens
    //     await instanceTokenASD.approve(instanceBamiIDO2.address, ethers.constants.MaxUint256);
    //     await instanceBinanceCoin.approve(instanceBamiIDO2.address, ethers.constants.MaxUint256);
    //     // safeMint hes to contract
    //     await instanceTokenAFC.mint(instanceBamiIDO2.address, ethers.utils.parseEther("1000000"));
    //     await instanceTokenAFC.mint(instanceBamiHesmanIDO.address, ethers.utils.parseEther("1000000")); // refund hesman

    //     // set time stake
    //     await instanceBamiIDO2.setTimeStake(1654581600, 1654614000, 1654614001);
    //     // set time buy
    //     await instanceBamiIDO2.setBuyTime(1654581600, 1654614000);
    //     // set time claim
    //     await instanceBamiIDO2.setClaimTime([1654581600,1654581601,1654581602,1654581603], [25,25,25,25]);
    //     await instanceBamiHesmanIDO.setClaimTime([1654581600,1654581601,1654581602,1654581603], [25,25,25,25]);

    //     // stake
    //     await instanceBamiIDO2.stakeBamiGetSlot();

    //     // console.log(await instanceTokenASD.balanceOf(owner.address));
    //     // console.log(await instanceTokenASD.balanceOf(addr1.address));
    //     // console.log(await instanceTokenASD.balanceOf(addr2.address));
    //     // console.log(await instanceTokenASD.balanceOf(instanceBamiIDO2.address));

    //     // buy
    //     await instanceBamiIDO2.buyIdo();

    //     // claim
    //     await instanceBamiIDO2.claimIdo();

    //     // add whitelist
    //     await instanceBamiHesmanIDO.setWhiteList([owner.address],[owner.address],[owner.address]);

    //     //claim
    //     await instanceBamiHesmanIDO.claimPool2();
    //     await instanceBamiHesmanIDO.claimPool2();
    //     await instanceBamiHesmanIDO.claimPool2();


    //     console.log(await instanceTokenAFC.balanceOf(owner.address));
    // });

    // it("Pool1", async function () {
    //     const [owner, addr1, addr2] = await ethers.getSigners();
    //     const TokenAFC = await ethers.getContractFactory("TokenAFC");
    //     const BinanceCoin = await ethers.getContractFactory("BinanceCoin");
    //     const RunTogetherBoxNFT = await ethers.getContractFactory("RunTogetherBoxNFT");
    //     const HesmanIDO = await ethers.getContractFactory("HesmanIDO");
    //     const HemanRefundIDO = await ethers.getContractFactory("HemanRefundIDO");
    //     const HemanNftIDO = await ethers.getContractFactory("HemanNftIDO");

    //     const instanceTokenAFC = await TokenAFC.deploy(); //hesman
    //     const instanceBinanceCoin = await BinanceCoin.deploy();
    //     const instanceRunTogetherBoxNFT = await RunTogetherBoxNFT.deploy();
    //     const instanceHesmanIDO = await HesmanIDO.deploy(owner.address, instanceTokenAFC.address, instanceBinanceCoin.address, instanceRunTogetherBoxNFT.address);
    //     const instanceHemanRefundIDO = await HemanRefundIDO.deploy(instanceHesmanIDO.address, instanceBinanceCoin.address, owner.address);
    //     const instanceHemanNftIDO = await HemanNftIDO.deploy(instanceHesmanIDO.address, instanceHemanRefundIDO.address, instanceTokenAFC.address, owner.address);

    //     //unpause
    //     await instanceHesmanIDO.setPauseContract(false);
    //     await instanceHemanRefundIDO.setPauseContract(false);
    //     await instanceHemanNftIDO.setPauseContract(false);
    //     // approve
    //     await instanceRunTogetherBoxNFT.setApprovalForAll(instanceHesmanIDO.address, true);
    //     await instanceBinanceCoin.approve(instanceHesmanIDO.address, ethers.constants.MaxUint256);
    //     // safeMint hes to contract
    //     await instanceTokenAFC.mint(instanceHesmanIDO.address, ethers.utils.parseEther("1000000"));
    //     await instanceBinanceCoin.mint(instanceHemanRefundIDO.address, ethers.utils.parseEther("1000000"));
    //     await instanceBinanceCoin.mint(owner.address, ethers.utils.parseEther("250"));
    //     await instanceTokenAFC.mint(instanceHemanNftIDO.address, ethers.utils.parseEther("1000000"));

    //     // set time stake
    //     await instanceHesmanIDO.setTimeStake(1654678800, 1654700400, 1654700401);
    //     // set time buy
    //     await instanceHesmanIDO.setBuyTime(1654678800, 1654700400);
    //     // set time refund
    //     await instanceHemanRefundIDO.setTimeRefund(1654678800, 1654700400);
    //     // set time claim
    //     await instanceHesmanIDO.setClaimTime([1654678800,1654678801,1654678802,1654678803], [25,25,25,25]);
    //     await instanceHemanNftIDO.setClaimTime([1654678800,1654678801,1654678802,1654678803], [25,25,25,25]);

    //     // mint nft
    //     await instanceRunTogetherBoxNFT.safeMint(owner.address);


    //     // stake
    //     await instanceHesmanIDO.stakeNftGetSlot([0]);

    //     // buy
    //     await instanceHesmanIDO.buyIdo();

    //     // claim old
    //     await instanceHesmanIDO.claimIdo();

    //     //-----Refund------
    //     // add whitelist
    //     await instanceHemanRefundIDO.setWhiteList([owner.address]);

    //     // refund
    //     await instanceHemanRefundIDO.refund();

    //     //-----New claim------
    //     // add whitelist
    //     await instanceHemanNftIDO.setWhiteList([owner.address]);

    //     //claim new
    //     await instanceHemanNftIDO.claimIdo();
    //     await instanceHemanNftIDO.claimIdo();
    //     await instanceHemanNftIDO.claimIdo();
    //     // await instanceHemanNftIDO.claimIdo();

    //     console.log(ethers.utils.formatEther(await instanceTokenAFC.balanceOf(owner.address)));
    // });
});