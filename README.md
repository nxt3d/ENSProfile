# ENSProfile - A User Profile Resolver for L2s

ENSProfile is a resolver built for Layer 2 (L2) chains, specifically designed for an **ENS L2**. It enables users to set up a single profile that can manage the complete set of ENS records, while also allowing for dynamic expansion through extensions. ENSProfile provides secure and scalable ENS resolution on L2, while ensuring honesty and trust via proofs that validate the state of L2 on L1 Ethereum.

### Key Features

1. **Unified ENS Records for L2 Users**: Users can set up this profile once and use it as the resolver for all their ENS names on L2. This eliminates the need to manage individual records for each ENS name—simply point multiple names to this profile and manage your records from one place.

2. **Dynamic Profile Extensions**:
   - ENSProfile introduces a concept of **Profile Extensions**, which dynamically expand the capabilities of the profile by adding "synthetic" hook records.
   - Synthetic hook records are resolved by external smart contracts (profile extensions) on L1 and can be resolve cross-chain data using proofs.
   - Extensions are added to the ENS Profile using their namespace, such as "eth.extension".
   - Clients are able to resolve hooks, for example, "eth.extension.favoriteColor," as long as the namespace of the extension is added in the ENS Profile and the hook has been registered on L1 in the .eth resolver.
   - Extensions can use Unruggable Gateways, which supports multiple L2s including OP Mainnet, Base, Arbitrum, ZKsync, Scroll, and others, to resolve cross-chain records.

3. **L2-to-L1 Proving**:
   - **ENSProfile is specifically designed for Layer 2 (L2) chains**, where gateways are used to resolve names on L2.
   - To ensure these gateways are honest, we use proofs. This involves verifying the state root of the L2 chain on L1 Ethereum to ensure that the data provided by gateways is accurate and hasn't been tampered with.

### Example: Synthetic Hook Records Format

Synthetic hook records for Profile Extensions use a namespace key format to allow for hook records to be resolved by the L1 resolver. Here's an example of the format for a verification hook that returns `true`:

```eth.verifier-extension.is-verified```

This format ensures that only the owner of the namespace can register the Profile Extension on L1 Ethereum. Once the extension is registered on L1 Ethereum, users can add the extension to their ENS Profile to start resolving the synthetic hook records.  

## Hooks

Hooks are a new record type that is basically a text record that can only be resolved from one resolver address on a specific chain. 

The hook function looks like:

```hook(node, key, address, coinType);```

The `address` and `coinType` are checked by the resolver to make sure that they match the address and chain of the resolver. This could be considered unnecessary as the client should know what the resolver address and coinType of the chain are and can check the address before making the call. However, making the client input the address and coinType also ensures that the client is aware that hooks can only be resolved from specific resolvers and are not valid for other resolvers, even with the same address on a different chain.

---

## Foundry

#### Build

```$ forge build```

#### Test

```$ forge test```