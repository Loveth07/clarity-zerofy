[Previous test content plus new tests...]

Clarinet.test({
  name: "Cannot create certificate with zero or negative amount",
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
        "create-offset-certificate",
        [types.uint(0)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[1].result, '(err u102)');
  },
});

Clarinet.test({
  name: "Unregistered business cannot create certificate",
  async fn(chain: Chain, accounts: Map<string, Account>) {
    const wallet_1 = accounts.get("wallet_1")!;
    
    let block = chain.mineBlock([
      Tx.contractCall(
        "zerofy",
        "create-offset-certificate",
        [types.uint(500)],
        wallet_1.address
      )
    ]);
    
    assertEquals(block.receipts[0].result, '(err u101)');
  },
});
