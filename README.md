
This project is developed on the SUI Blockchain using SUI Move, serving as an NFT marketplace and launchpad. Below, you'll find a brief overview of the key modules and functionalities implemented in this project.

### Modules

#### 1. **Marketplace Module**
- **Description**: Handles the operations related to the NFT marketplace, including listing, delisting, editing asks, and buying NFTs.
- **Structures**:
  - `Marketplace`: Represents the marketplace with essential details such as ID, owner, fee, and fee balance.
  - `AuctionListing`: Defines an auction listing with details like ID, item ID, bid, collateral, etc.
- **Functions**:
  - `init`: Initializes the marketplace.
  - `list`: Lists an NFT in the marketplace.
  - `delist`: Removes an NFT listing from the marketplace.
  - `edit_ask`: Modifies the asking price of a listed NFT.
  - `buy`: Facilitates the purchase of an NFT from the marketplace.

#### 2. **Launchpad Module**
- **Description**: Manages the launchpad functionalities, including token presales, minting NFTs, buying NFTs, etc.
- **Structures**:
  - `LaunchPadData`: Represents the launchpad data containing admin details, pricing, sale information, etc.
  - `NFTPresaleInfo`: Stores information about a presale event for NFTs.
- **Functions**:
  - `init`: Initializes the launchpad.
  - `initiate_launchpad`: Sets up the launchpad with necessary configurations.
  - `set_presale`: Sets up a presale event for NFTs.
  - `launch_pre_sale`: Initiates the presale event.
  - `launch_public_sale`: Launches the public sale of NFTs.
  - `set_co_owners`: Sets co-owners for the launchpad.
  - `mint_nft_and_store_admin`: Mints NFTs and stores them in the launchpad.
  - `buy_nft`: Allows users to buy NFTs from the launchpad.
  - `buy_nft_pre_sale`: Allows users to buy NFTs from presale events.
  - `redeem_funds`: Enables the admin to redeem collected funds from NFT sales.

### Usage
- **Dependencies**: This project relies on the SUI Blockchain and SUI Move language.
- **Instructions**: Detailed instructions on deploying and interacting with the marketplace and launchpad modules will be provided separately.

### Note
This README provides an overview of the project structure and functionality.
