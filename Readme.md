# Ethers zig (dummy)
It implements the ethers js contract initialization style using zig comptime. This is a practice project built to master zig comptime.

Ether js contract initialisation from the [doc](https://docs.ethers.org/v6/getting-started/#starting-contracts):
```js
abi = [
  "function decimals() view returns (string)",
  "function symbol() view returns (string)",
  "function balanceOf(address addr) view returns (uint)"
]

// Create a contract
contract = new Contract("dai.tokens.ethers.eth", abi, provider)
sym = await contract.symbol()
```

Ethers zig comptime contract initialisation:
```js
const fns = [_][:0]const u8{
    "function decimals() view returns (string)",
    "function symbol() view returns (string)",
    "function balanceOf(address addr) view returns (uint)",
    "function transfer(address to, uint amount)",
    "event Transfer(address indexed from, address indexed to, uint amount)",
};
const contact = Contract(&fns).init(); // init should be able to accept provider and contract address
// balanceOf is now available to the contract instance
const balance = try contact.functions.balanceOf.call(.{ .addr = "eltneg.eth" });
std.debug.print("balance={?}\n", .{balance.value});
```

#### **Run `zig run main.zig` to see it in action**
