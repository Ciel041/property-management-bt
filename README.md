# Blockchain-Based Intellectual Property and Project Ownership Registry

A university mini-project that records a project title, owner address, and document hash on an Ethereum-compatible chain. The hash is the integrity check: if the file changes, its SHA-256 no longer matches the value stored in the contract.

This demo is not a legal copyright filing. Use a test network and test funds only.

## What is in this folder

| File | Role |
| --- | --- |
| `IPRegistry.sol` | Registry contract: register, transfer ownership, verify a hash |
| `index.html` | MetaMask frontend (HTML, CSS, ethers.js v6) |
| `README.md` | Deploy and demo steps |

The contract keeps one mapping:

- key: `bytes32` document hash
- value: title, owner, block timestamp, and an `exists` flag

Each registration writes `block.timestamp`. `ProjectRegistered` and `OwnershipTransferred` log every state change. Failed calls revert with `require`, so Remix and the webpage can show the reason.

## 1. Compile and deploy in Remix

1. Open [Remix IDE](https://remix.ethereum.org).
2. In the **File Explorer**, create a file named `IPRegistry.sol` and paste in the contract from this folder.
3. Open the **Solidity Compiler** tab.
4. Set the compiler to **0.8.20** or any other `0.8.x` release. The source uses `pragma solidity ^0.8.0`.
5. Click **Compile IPRegistry.sol**. Fix nothing if the green check appears. Warnings about the SPDX license should not appear; the file already has `SPDX-License-Identifier: MIT`.
6. Install [MetaMask](https://metamask.io/) if it is not installed, then create or unlock a wallet.
7. In MetaMask, switch the network to **Sepolia** (or another testnet you can obtain test ETH for). Do not deploy this demo on Ethereum mainnet.
8. Get test ETH from a Sepolia faucet if the account balance is zero.
9. In Remix, open **Deploy & Run Transactions**.
10. Set **Environment** to **Injected Provider - MetaMask**. Approve the connection. The account shown in Remix must be the MetaMask account you intend to use as the first owner.
11. Confirm the contract dropdown says `IPRegistry`. Leave the constructor empty; this contract has no constructor arguments.
12. Click **Deploy** and confirm the transaction in MetaMask.
13. After it is mined, copy the contract address under **Deployed Contracts**. It looks like `0x` followed by 40 hex characters.

## 2. Put the address and ABI into the frontend

Open `index.html` and edit the script near `CONTRACT_ADDRESS`.

1. Replace `PASTE_DEPLOYED_CONTRACT_ADDRESS` with the address you copied from Remix. Keep the quotes.

```javascript
const CONTRACT_ADDRESS = "0xYourDeployedAddress";
```

2. The file already contains a human-readable ABI that matches `IPRegistry.sol`. You only need to replace `CONTRACT_ABI` if you changed function names, parameters, or events.
3. If you did change the contract, copy the new ABI from Remix:
   - Solidity Compiler → **Compilation Details** → **ABI**, or
   - click the copy icon beside the ABI in the compile artifacts.
4. Paste that JSON array in place of `CONTRACT_ABI`, save the file, and reload the page.

The webpage and MetaMask must use the **same network** you selected in Remix. A Sepolia address will not answer calls made from another chain.

## 3. Run the frontend locally

MetaMask will not inject into a `file://` page reliably. Serve the folder over HTTP.

From this project folder, use either:

```bash
python -m http.server 5500
```

On Windows, if `python` opens the Microsoft Store instead of running, use the Python launcher:

```bash
py -3 -m http.server 5500
```

Or, if Node.js is installed:

```bash
npx serve -l 5500
```

Open [http://localhost:5500](http://localhost:5500).

1. Click **Connect MetaMask** and approve the connection.
2. The header should show a shortened address and the chain id (Sepolia is `11155111`).
3. Register a project:
   - Enter a title.
   - Paste a 64-character SHA-256 hex string, or click **Hash a local file** and choose a document. The page computes SHA-256 in the browser and fills the hash field. The file itself is not uploaded.
   - Click **Register on-chain** and confirm in MetaMask.
4. Copy that same hash into **Verify integrity** and look it up. The page shows the title, owner address, and the timestamp stored at registration.
5. Optional: transfer the project to a second address. Connect that second wallet afterward and verify again; the owner field should be the new address.

## Negative tests to show in the demo

Try these after one successful registration. The red status line should show the revert reason, or a MetaMask rejection if you cancel the popup.

| Action | Expected result |
| --- | --- |
| Register the same hash again | `Hash already registered` |
| Submit an empty title (bypass the form by calling Remix) | `Title required` |
| Register hash `0x` + 64 zeros | `Invalid document hash` |
| Verify a hash that was never registered | `No record for this hash` |
| Transfer from a wallet that is not the owner | `Not the owner` |
| Transfer to `0x0000…0000` | `Invalid new owner` |
| Transfer to the current owner | `Already the owner` |
| Reject the MetaMask popup | `MetaMask rejected the request. Nothing was sent.` |
| Leave the placeholder contract address unchanged | Message asking you to paste the deployed address |

You can run the same checks from Remix under **Deployed Contracts** by calling `registerProject`, `transferOwnership`, and `verifyDocument` with a second account (set that account in MetaMask, or use Remix's account dropdown only if you deployed with the Remix VM instead of MetaMask).

## How the integrity check works

1. SHA-256 turns the document into a 32-byte fingerprint.
2. `registerProject` stores that fingerprint with the title, `msg.sender`, and `block.timestamp`.
3. `verifyDocument` returns those fields only when the identical hash exists.
4. Editing the file changes the hash, so the lookup no longer finds the original record.

Events remain in the transaction receipt and in the chain log even after you close the page. In Remix, expand the successful transaction and read `ProjectRegistered` or `OwnershipTransferred`.
