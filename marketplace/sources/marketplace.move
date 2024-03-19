module marketplace::moonpad_marketplace {
    use std::option::{Self, Option};
    use std::type_name::{Self, TypeName};
    
    use sui::tx_context::{Self,sender, TxContext};
    use sui::object::{Self, UID, ID};
    use sui::transfer;
    use sui::event;
    use sui::dynamic_object_field as dof;
    use sui::coin::Coin;
    use sui::sui::SUI;
    use sui::balance::{Self, Balance};
    use sui::package;
    use sui::coin;

    use common::nft::Nft;
    use common::collection::{Self ,Collection};

    struct Marketplace has key {
        id: UID,
        owner: address,
        fee: u16,
        fee_balance: Balance<SUI>
    }

   struct AuctionListing<phantom T: key + store> has key {
        id: UID,
        item_id: ID,
        bid: Balance<SUI>,
        collateral: Balance<SUI>,
        min_bid: u64,
        min_bid_increment: u64,
        starts: u64,
        expires: u64,
        owner: address,
        bidder: address
    }
    
    struct MOONPAD_MARKETPLACE has drop {}

    struct Witness has drop {}

    struct Listing<phantom T> has key, store {
        id: UID,
        item_id: ID,
        ask: u64,
        owner: address
    }

    struct ListItemEvent has copy, drop {
        item_id: ID,
        ask: u64,
        auction: bool,
        type_name: TypeName,
    }

    struct DelistItemEvent has copy, drop {
        item_id: ID,
        sale_price: u64,
        sold : bool,
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
        };
        
        transfer::share_object(marketplace);
    }

    public entry fun list<T>(
        marketplace: &mut Marketplace,
        item: Nft<T>,
        ask: u64,
        ctx: &mut TxContext
    ) {
        list_and_get_id(marketplace, item, ask, ctx);
    }

    public fun list_and_get_id<T>(
        marketplace: &mut Marketplace,
        item: Nft<T>,
        ask: u64,
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
        };
        let id = object::id(&listing); 
        dof::add(&mut marketplace.id, id, listing);
        dof::add(&mut marketplace.id, item_id, item);
        id
    }

    public entry fun delist<T>(
        marketplace: &mut Marketplace,
        listing_id: ID,
        ask: u64,
        ctx: &mut TxContext
    ){
        assert!(dof::exists_(&marketplace.id , listing_id),00);
        let listing = dof::remove(&mut marketplace.id, listing_id);
        let Listing<T> { id, item_id, ask : _, owner  } = listing;
        assert!(owner  == tx_context::sender(ctx), 0);

        object::delete(id);

        let nft : Nft<T> = dof::remove(&mut marketplace.id, item_id);
        transfer::public_transfer(nft,owner)
    }
    public entry fun edit_ask<T>(
        marketplace: &mut Marketplace,
        listing_id: ID,
        new_ask: u64,
        ctx: &mut TxContext
    ){
        assert!(dof::exists_(&marketplace.id , listing_id),00);
        let listing : &mut Listing<T> = dof::borrow_mut(&mut marketplace.id, listing_id);
        let ask = &mut listing.ask;
        assert!(listing.owner  == tx_context::sender(ctx), 0);
        
        *ask = new_ask;
    }

    public entry fun buy<T>(
        marketplace: &mut Marketplace,
        collection: &mut Collection<T>,
        listing_id: ID,
        paid: Coin<SUI>,
        ctx: &mut TxContext
    ){
        let listing = dof::remove<ID, Listing<T>>(&mut marketplace.id, listing_id);
        let Listing { id, item_id, ask, owner  } = listing;
        let item = dof::remove<ID, Nft<T>>(&mut marketplace.id, item_id);
        object::delete(id);

        event::emit(DelistItemEvent {
            item_id: item_id,
            sale_price: ask,
            sold: true,
            type_name: type_name::get<T>(),
        });
        let share = collection::get_royality_percentage<T>(collection);
        let paid_amount = coin::value(&paid);
        let split_amount = paid_amount * (share as u64) /10_000;
        let receiver_coin =  coin::split(&mut paid , split_amount , ctx);
        let fee_coin =  coin::split(&mut paid , (marketplace.fee as u64) , ctx);

        coin::put<SUI>( &mut marketplace.fee_balance , fee_coin);
        transfer::public_transfer(receiver_coin , collection::get_receiver_address<T>(collection));
        transfer::public_transfer(paid ,owner );
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

}
