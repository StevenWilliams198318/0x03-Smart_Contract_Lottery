# 🎰 Smart Contract Lottery (0x03-Smart_Contract_Lottery)

A decentralized lottery smart contract built with Solidity and Foundry. Participants can enter the lottery by sending ETH, and a winner is randomly selected and rewarded with the total pool. This project is designed to demonstrate randomness, secure value transfers, and Solidity best practices.

---

## 📂 Project Structure

0x03-Smart_Contract_Lottery/
├── lib/ # Dependencies (e.g., forge-std)
├── script/ # Deployment scripts
├── src/ # Main contract (Lottery.sol)
├── test/ # Unit tests
├── foundry.toml # Foundry configuration
└── README.md
---

## ⚙️ Features

- ✅ Players enter by sending ETH
- ✅ Only the owner can pick the winner
- ✅ Random winner selection (pseudo or oracle-based)
- ✅ Transparent and auditable
- ✅ Withdrawals handled securely

---

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/YOUR-USERNAME/0x03-Smart_Contract_Lottery.git
cd 0x03-Smart_Contract_Lottery
```
### 2. Install dependencies | Install Foundry
```bash
forge install
forge build
forge test
forge script script/Deploy.s.sol --rpc-url <YOUR_RPC_URL> --private-key <YOUR_PRIVATE_KEY> --broadcast
```

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test!

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
