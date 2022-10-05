Moralis.Cloud.define("EventSales", async (request) => {
    var pipeline = [
        { sort: { block_timestamp: -1 } },
    ];

    const queryBuy = new Moralis.Query("EventBuyCompleted");
    const resultBuy = JSON.parse(JSON.stringify(await queryBuy.find()));
    for (let i = 0; i < resultBuy.length; ++i) {
        pipeline.push({ match: { saleId: { $ne: resultBuy[i].saleIndex } } });
    }

    const queryDelist = new Moralis.Query("EventDelistItem");
    const resultDelist = await queryDelist.find();
    for (let i = 0; i < resultDelist.length; ++i) {
        let data = JSON.parse(JSON.stringify(resultDelist[i]));
        pipeline.push({ match: { saleId: { $ne: data.saleIndex } } });
    }

    if (request.params) {
        if (request.params.price == "asc") {
            pipeline.push({ sort: { priceListing_decimal: 1 } });
        }
        if (request.params.price == "desc") {
            pipeline.push({ sort: { priceListing_decimal: -1 } });
        }
        if (request.params.page) {
            var skip = (request.params.page - 1) * 9;
            var limit = 9;
            pipeline.push({ skip: skip });
            pipeline.push({ limit: limit });
        }
    }

    const query = new Moralis.Query("EventNewSales");
    const results = JSON.parse(JSON.stringify(await query.aggregate(pipeline)));

    return results;
});

Moralis.Cloud.define("history", async (request) => {
    const walletAddress = request.params.wallet.toLowerCase();
    let result = [];

    const querySale = new Moralis.Query("EventNewSales");
    querySale.equalTo("seller", walletAddress);
    const resultSale = JSON.parse(JSON.stringify(await querySale.find()));

    for (let i = 0; i < resultSale.length; ++i) {
        result.push({
            "transaction_hash": resultSale[i].transaction_hash,
            "createdAt": resultSale[i].createdAt,
            "seller": resultSale[i].seller,
            "type": "EventNewSales"
        })
    }

    const queryBuy = new Moralis.Query("EventBuyCompleted");
    queryBuy.equalTo("buyer", walletAddress);
    const resultBuy = JSON.parse(JSON.stringify(await queryBuy.find()));

    for (let i = 0; i < resultBuy.length; ++i) {
        result.push({
            "transaction_hash": resultBuy[i].transaction_hash,
            "createdAt": resultBuy[i].createdAt,
            "buyer": resultBuy[i].buyer,
            "type": "EventBuyCompleted"
        })
    }

    const queryDelist = new Moralis.Query("EventDelistItem");
    queryDelist.equalTo("seller", walletAddress);
    const resultDelist = JSON.parse(JSON.stringify(await queryDelist.find()));

    for (let i = 0; i < resultDelist.length; ++i) {
        result.push({
            "transaction_hash": resultDelist[i].transaction_hash,
            "createdAt": resultDelist[i].createdAt,
            "seller": resultDelist[i].seller,
            "type": "EventDelistItem"
        })
    }

    return result;
});

Moralis.Cloud.define("StakeToVote", async (request) => {
    const id = request.params.id;
    const queryVote = new Moralis.Query("StakeToVoteComplete");
    queryVote.equalTo("proposalOrder", id);
    const resultVote = JSON.parse(JSON.stringify(await queryVote.find()));

    return resultVote;
});
