const NFT = artifacts.require("NFT");

contract("NFT", accounts => {
    let instance;
    before(async () => {
        instance = await NFT.deployed();
        console.log(instance.address);
    });


    it("Should deployed NFT Market Place properly.", async () => {
        assert(instance.address !== '');
    })

    it("NFT mint by Accounts[1]", async () => {
        let _mint= await instance.mint("myFirst",{from: accounts[1]});
        assert(_mint.logs[0].event == "Transfer");
        // console.log((_mint.logs[0]));
    })

    it("NFT Owner should be minter", async () => {
        let ownerNFT= await instance.getItemDetails(1);
        assert(ownerNFT.currentOwner == accounts[1]);
    })

    it("Auction should be started.", async () => {
        await instance.startAuction(1, 1, 4,{from: accounts[1]});
        let auctionStarted= await instance.getItemDetails(1);
        assert(auctionStarted.auctionStart);
    })

    it("Contract balance should be zero before biding.", async () => {
        let contractBal= await instance.getBalance();
        // console.log(contractBal);
        assert(contractBal == 0 );
    })

    it("PlaceBid", async () => {
        await instance.placeBid(1,{value: web3.utils.toWei("2","ether"), from: accounts[2]});
        await instance.placeBid(1,{value: web3.utils.toWei("3","ether"), from: accounts[3]});
        await instance.placeBid(1,{value: web3.utils.toWei("4","ether"), from: accounts[4]});
    })

    it("Contract balance should be 9 ETH.", async () => {
        let contractBal= await instance.getBalance();
        // console.log(contractBal);
        assert(contractBal == web3.utils.toWei("9","ether") );
    })

    it("Highest bider should be Accounts[4]", async () => {
        let highestBider= await instance.biders(1);
        assert(highestBider.biderAddress == accounts[4]);
    })


    it("NFT should be transfer to Highest Bider.", async ()=>{
            let result = await instance.transferNFT(1,{from: accounts[1]});
            // console.log(await result);
            let getItem= await instance.getItemDetails(1);
            assert(getItem.currentOwner == accounts[4]);
    })

    it("Withdraw Amount", async ()=>{
        let Am1= await instance.withdrawal(1,{from: accounts[2]});
        // console.log(Am1);
        let Am2= await instance.withdrawal(1,{from: accounts[3]});
        // console.log(Am2);
    })    

    it("Contract balance should be zero after Withdraw.", async () => {
        let contractBal= await instance.getBalance();
        // console.log(contractBal);
        assert(contractBal == 0);
    })

    it("Auction should be ended.", async () => {
        let auctionStarted= await instance.getItemDetails(1);
        assert(!auctionStarted.auctionStart);
    })
})
