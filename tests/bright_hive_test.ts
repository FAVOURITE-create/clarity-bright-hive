Clarinet.test({
  name: "Contract pause functionality works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    // First create required category and collection
    let setupBlock = chain.mineBlock([
      Tx.contractCall('bright-hive', 'create-category', [
        types.ascii("Technology"),
        types.bool(true)
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-collection', [
        types.uint(1),
        types.ascii("Test Collection"),
        types.bool(true)
      ], deployer.address)
    ]);
    
    setupBlock.receipts.forEach(receipt => receipt.result.expectOk());
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'toggle-contract-pause', [], deployer.address),
      Tx.contractCall('bright-hive', 'create-idea', [
        types.ascii("Test Idea"),
        types.utf8("Description"),
        types.uint(1),
        types.ascii("Technology")
      ], wallet1.address)
    ]);
    
    block.receipts[0].result.expectOk().expectBool(true);
    block.receipts[1].result.expectErr().expectUint(105); // err-contract-paused
  },
});

[Rest of tests remain unchanged...]
