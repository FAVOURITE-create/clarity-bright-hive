// [Previous test content remains unchanged, adding new tests...]

Clarinet.test({
  name: "Contract pause functionality works correctly",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
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

// Add more tests for new functionality...
