module moonpad::collection {
    use std::type_name::{Self, TypeName};
    use std::option::Option;
    use std::string;

    use sui::event;
    use sui::package::{Self, Publisher};
    use sui::display::{Self, Display};
    use sui::transfer;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::TxContext;
    use sui::dynamic_field as df;

    use moonpad::witness::Witness as DelegatedWitness;
    use moonpad::frozen_publisher::{Self, FrozenPublisher};

    const EUndefinedDomain: u64 = 1;

    const EExistingDomain: u64 = 2;

    struct Witness has drop {}


    struct Collection<phantom T> has key, store {
        id: UID,
        collection_name : string::String,
        collection_symbol : string::String,
        receiver: address , 
        royality : u64,
    }

    struct MintCollectionEvent has copy, drop {
        collection_id: ID,
        type_name: TypeName,
    }


    public fun create<T>(
        _witness: DelegatedWitness<T>,
        receiver: address , 
        royality : u64,
        collection_name: string::String,
        collection_symbol: string::String,
        ctx: &mut TxContext,
    ): Collection<T> {
        create_( receiver ,royality,collection_name,collection_symbol ,ctx)
    }

    fun create_<T>( 
        receiver: address , 
        royality : u64,
        collection_name: string::String,
        collection_symbol: string::String,
        ctx: &mut TxContext
        ): Collection<T> {
        let id = object::new(ctx);

        event::emit(MintCollectionEvent {
            collection_id: object::uid_to_inner(&id),
            type_name: type_name::get<T>(),
        });

        Collection { id,receiver , royality ,collection_name , collection_symbol}
    }


    public fun get_receiver_address<C>(collection: &Collection<C>): address {
        collection.receiver
    }

    public fun borrow_uid_mut<C>(
        _witness: DelegatedWitness<C>,
        collection: &mut Collection<C>,
    ): &mut UID {
        &mut collection.id
    }


    public entry fun delete<C>(collection: Collection<C>) {
        let Collection { id ,receiver: _, royality: _ ,collection_name,collection_symbol } = collection;
        object::delete(id);
    }

           
 
    public fun new_display<T>(
        _witness: DelegatedWitness<T>,
        pub: &FrozenPublisher,
        ctx: &mut TxContext,
    ): Display<Collection<T>> {
        let display =
            frozen_publisher::new_display<Witness, Collection<T>>(Witness {}, pub, ctx);

        display::add(&mut display, string::utf8(b"collection_name"), string::utf8(b"{collection_name}"));
        display::add(&mut display, string::utf8(b"Collection_symbol"), string::utf8(b"{collection_symbol}"));

        display
    }

    // === Test-Only ===

    #[test_only]
    public fun test_create_with_mint_cap<T>(
        supply: Option<u64>,
        ctx: &mut TxContext,
    ): (Collection<T>, MintCap<T>) {
        let collection = create_(ctx);
        let mint_cap = mint_cap::test_create_mint_cap(
            object::id(&collection), supply, ctx
        );

        (collection, mint_cap)
    }
}
