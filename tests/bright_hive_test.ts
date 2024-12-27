import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can create a new collection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("My First Collection")
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    block.receipts[0].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can create an idea in a collection",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("My First Collection")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-idea', [
        types.ascii("Great Idea"),
        types.utf8("This is a fantastic idea description"),
        types.uint(1)
      ], deployer.address)
    ]);
    
    assertEquals(block.receipts.length, 2);
    block.receipts[1].result.expectOk().expectUint(1);
  },
});

Clarinet.test({
  name: "Can vote on an idea",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("My First Collection")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-idea', [
        types.ascii("Great Idea"),
        types.utf8("This is a fantastic idea description"),
        types.uint(1)
      ], deployer.address),
      Tx.contractCall('bright-hive', 'vote-idea', [
        types.uint(1)
      ], wallet1.address)
    ]);
    
    assertEquals(block.receipts.length, 3);
    block.receipts[2].result.expectOk().expectBool(true);
  },
});

Clarinet.test({
  name: "Can add comments to an idea",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get('deployer')!;
    const wallet1 = accounts.get('wallet_1')!;
    
    let block = chain.mineBlock([
      Tx.contractCall('bright-hive', 'create-collection', [
        types.ascii("My First Collection")
      ], deployer.address),
      Tx.contractCall('bright-hive', 'create-idea', [
        types.ascii("Great Idea"),
        types.utf8("This is a fantastic idea description"),
        types.uint(1)
      ], deployer.address),
      Tx.contractCall('bright-hive', 'add-comment', [
        types.uint(1),
        types.utf8("This is a great comment!")
      ], wallet1.address)
    ]);
    
    assertEquals(block.receipts.length, 3);
    block.receipts[2].result.expectOk().expectUint(1);
  },
});