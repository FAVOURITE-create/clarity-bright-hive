import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create and manage categories",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'add-category', [
        types.ascii("Technology")
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    block.receipts[0].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Can create a new collection with category",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'add-category', [
        types.ascii("Technology")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("Tech Ideas"),
        types.ascii("Technology")
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can create an idea with category and claim rewards",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'add-category', [
        types.ascii("Technology")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("Tech Ideas"),
        types.ascii("Technology")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-idea', [
        types.ascii("Great Tech Idea"),
        types.utf8("Revolutionary tech solution"),
        types.uint(1),
        types.ascii("Technology")
      ], deployer.address)
    ]);
    
    // Add votes to meet threshold
    let voteBlock = chain.mineBlock([
      Tx.contractCall('bright-hive', 'vote-idea', [types.uint(1)], wallet1.address),
      Tx.contractCall('bright-hive', 'vote-idea', [types.uint(1)], accounts.get('wallet_2')!.address),
      Tx.contractCall('bright-hive', 'vote-idea', [types.uint(1)], accounts.get('wallet_3')!.address),
      Tx.contractCall('bright-hive', 'vote-idea', [types.uint(1)], accounts.get('wallet_4')!.address),
      Tx.contractCall('bright-hive', 'vote-idea', [types.uint(1)], accounts.get('wallet_5')!.address)
    ]);

    // Claim reward
    let rewardBlock = chain.mineBlock([
      Tx.contractCall('bright-hive', 'claim-idea-reward', [
        types.uint(1)
      ], deployer.address)
    ]);
    
    rewardBlock.receipts[0].result.expectOk().expectBool(true);
  },
});

// Include existing tests...
