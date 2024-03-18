

module marketplace::moonpad_marketplace {
    use std::option::{Self, Option};
    use std::type_name::{Self, TypeName};
    use sui::clock::{Self, Clock};
    
    use sui::tx_context::{Self,sender, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::event;
    use sui::dynamic_object_field as dof;
    use sui::coin::{Self, Coin};
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::package;

    use common::nft::{Self, Nft};
    use common::collection::{Self ,Collection};


    
    const MaxFee: u16 = 2000; // 20%! Way too high, this is mostly to prevent accidents, like adding an extra 0
    const MaxWalletFee: u16 = 125;

    // For when amount paid does not match the expected.
    const EAmountIncorrect: u64 = 135289670000;
    // For when someone tries to delist without ownership.
    const ENotOwner: u64 = 135289670000 + 1;
    // For when someone tries to use fallback functions for a standardized NFT.
    const EMustUseStandard: u64 = 135289670000 + 2;
    const EMustNotUseStandard: u64 = 135289670000 + 3;
    // For auctions
    const ETooLate: u64 = 135289670000 + 100;
    const ETooEarly: u64 = 135289670000 + 101;
    const ENoBid: u64 = 135289670000 + 102;

    struct Marketplace has key {
        id: UID,
        owner: address,
        fee: u16,
        fee_balance: Balance<SUI>,
        collateralFee: u64,
    }

    // OTW
    struct MOONPAD_MARKETPLACE has drop {}

    struct Witness has drop {}


    /// A single listing which contains the listed item and its price in [`Coin<C>`].
    // Potential improvement: make each listing part of a smaller shared object (e.g. per type, per seller, etc.)
    // store market details in the listing to prevent any need to interact with the Marketplace shared object?
    struct Listing<phantom T> has key, store {
        id: UID,
        item_id: ID,
        ask: u64, // Coin<C>
        owner: address,
        seller_wallet: Option<ID>,
    }

    struct ListItemEvent has copy, drop {
        /// ID of the `Nft` that was listed
        item_id: ID,
        ask: u64,
        auction: bool,
        /// Type name of `Nft<C>` one-time witness `C`
        /// Intended to allow users to filter by collections of interest.
        type_name: TypeName,
    }

    struct DelistItemEvent has copy, drop {
        /// ID of the `Nft` that was listed
        item_id: ID,
        sale_price: u64,
        sold: bool,
        /// Type name of `Nft<C>` one-time witness `C`
        /// Intended to allow users to filter by collections of interest.
        type_name: TypeName,
    }

    fun init(otw: MOONPAD_MARKETPLACE, ctx: &mut TxContext) {
        package::claim_and_keep(otw, ctx);
        let id = object::new(ctx);

        let marketplace = Marketplace {
            id,
            owner: tx_context::sender(ctx),
            fee: 0,
            fee_balance: balance::zero<SUI>(),
            collateralFee: 0,
        };
        
        transfer::share_object(marketplace);
    }
/// List an item at the Marketplace.
    public entry fun list<T>(
        marketplace: &mut Marketplace,
        item: Nft<T>,
        ask: u64,
        ctx: &mut TxContext
    ) {
        list_and_get_id(marketplace, item, ask, option::none<ID>(), ctx);
    }

    public fun list_and_get_id<T>(
        marketplace: &mut Marketplace,
        item: Nft<T>,
        ask: u64,
        seller_wallet: Option<ID>,
        ctx: &mut TxContext
    ): ID {
        event::emit(ListItemEvent {
            item_id: object::id(&item),
            ask,
            auction: false,
            type_name: type_name::get<T>(),
        });

        let item_id = object::id<Nft<T>>(&item);

        let id = object::new(ctx);
        let listing = Listing<T> {
            id,
            item_id,
            ask,
            owner: tx_context::sender(ctx),
            seller_wallet,
        };
        let id = object::id(&listing); 
        dof::add(&mut marketplace.id, id, listing);
        dof::add(&mut marketplace.id, item_id, item);
        id
    }

    
    public entry fun buy<T>(
        marketplace: &mut Marketplace,
        collection: &mut Collection<T>,
        listing_id: ID,
        paid: Coin<SUI>,
        ctx: &mut TxContext
    ){
        let listing = dof::remove<ID, Listing<T>>(&mut marketplace.id, listing_id);
        let Listing { id, item_id, ask, owner, seller_wallet } = listing;
        let item = dof::remove<ID, Nft<T>>(&mut marketplace.id, item_id);
        object::delete(id);

        event::emit(DelistItemEvent {
            item_id: item_id,
            sale_price: ask,
            sold: true,
            type_name: type_name::get<T>(),
        });

        
     
        transfer::public_transfer(paid , collection::get_receiver_address<T>(collection));
        transfer::public_transfer(item , sender(ctx))
    }




    // getter functions for contracts to get info about our marketplace.
    public fun owner(
        market: &Marketplace,
    ): address {
        market.owner
    }

    public fun fee(
        market: &Marketplace,
    ): u16 {
        market.fee
    }

    public fun collateralFee(
        market: &Marketplace,
    ): u64 {
        market.collateralFee
    }

}
