# ENSProfile - A User Profile Resolver for L2s

ENSProfile is a resolver built for Layer 2 (L2) chains, specifically designed for an **ENS L2**. It enables users to set up a single profile that can manage the complete set of ENS records, while also allowing for dynamic expansion through hooks. ENSProfile provides secure and scalable ENS resolution on L2, while ensuring honesty and trust via proofs that validate the state of L2 on L1 Ethereum.

### Key Features

1. **Unified ENS Records for L2 Users**: Users can set up this profile once and use it as the resolver for all their ENS names on L2. This eliminates the need to manage individual records for each ENS name—simply point multiple names to this profile and manage your records from one place.

2. **Dynamic Profile Expansion with Hooks**:
   - ENSProfile introduces a concept of **Hooks**, which dynamically expand the capabilities of the profile by adding "synthetic" text records.
   - Synthetic text records are resolved by external smart contracts (hooks) and have a format that includes the hook's address, name, key, and parameters.
   - This allows users to add new features to their profiles over time without needing to redeploy or modify the main profile contract.
   - Hooks are also fully provable, because the request code, used for verifiying the storage of the hook can be dynamically loaded upon resolution, and used for verification on L1. Dynamic loading of request code could be part of a future release of Unruggable Gateways to support this feature.

3. **L2-to-L1 Proving**:
   - **ENSProfile is specifically designed for Layer 2 (L2) chains**, where gateways are used to resolve names on L2.
   - To ensure these gateways are honest we use proofs. This involves verifying the state root of the L2 chain on L1 Ethereum to ensure that the data provided by gateways is accurate and hasn't been tampered with.

### Example: Synthetic Text Records Format

Synthetic text records use a structured format to allow for text records to be resolved by hooks. Here's an example of the format for a follow hook that returns a subset of users the owner follows:

```
hook:follow:0,20:841b34aa32e63554FC00fe31705E06D129CA114f
```

In this format:
- `hook:follow`: Identifies the type of hook (in this case, a follow hook).
- `0,20`: Represents the range or subset of follows (from index 0 to 20).
- `841b3...`: The address of the hook (without the `0x` prefix).

---

## Foundry

#### Build

```
$ forge build
```

#### Test

```
$ forge test
```
