import {
  Clarinet,
  Tx,
  Chain,
  Account,
  types
} from 'https://deno.land/x/clarinet@v1.0.0/index.ts';
import { assertEquals } from 'https://deno.land/std@0.90.0/testing/asserts.ts';

Clarinet.test({
  name: "Can register a new business",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zerofy",
        "register-business",
        [types.ascii("Test Business")],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 1);
    assertEquals(block.height, 2);
    assertEquals(block.receipts[0].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Can add emissions to registered business",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zerofy",
        "register-business",
        [types.ascii("Test Business")],
        wallet_1.address
      ),
      Tx.contractCall(
        "zerofy",
        "add-emissions",
        [types.uint(1000)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Can create and verify offset certificate",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const deployer = accounts.get("deployer")!;
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zerofy",
        "create-offset-certificate",
        [types.uint(500)],
        wallet_1.address
      ),
      Tx.contractCall(
        "zerofy",
        "verify-certificate",
        [types.uint(1)],
        deployer.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[0].result.startsWith('(ok u'), true);
    assertEquals(block.receipts[1].result, '(ok true)');
  },
});

Clarinet.test({
  name: "Can transfer certificate between businesses",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    const wallet_2 = accounts.get("wallet_2")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zerofy",
        "create-offset-certificate",
        [types.uint(500)],
        wallet_1.address
      ),
      Tx.contractCall(
        "zerofy",
        "transfer-certificate",
        [types.uint(1), types.principal(wallet_2.address)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts.length, 2);
    assertEquals(block.receipts[1].result, '(ok true)');
  },
});
