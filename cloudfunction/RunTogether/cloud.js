Moralis.Cloud.define("StakeToVote", async (request) => {
    const id = request.params.id;
    const queryVote = new Moralis.Query("StakeToVoteComplete");
    queryVote.equalTo("proposalOrder", id);
    queryVote.descending("createdAt");
    const resultVote = JSON.parse(JSON.stringify(await queryVote.find()));

    return resultVote;
});
