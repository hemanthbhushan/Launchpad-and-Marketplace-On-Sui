module common::collection {
    use std::type_name::{Self, TypeName};
    use std::string::{Self,String};

    use sui::event;
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{sender ,TxContext};
    use common::utils;

    struct Witness has drop {}


    struct Collection<phantom T> has key, store {
        id: UID,
        collection_name : string::String,
        collection_symbol : string::String,
        admin : address,
        receiver: address , 
        royality : u64,
    }

    struct MintCollectionEvent has copy, drop {
        collection_id: ID,
        type_name: TypeName,
    }

   
    public fun create<OTW: drop, T>(
        _witness: OTW,
        collection_name: string::String,
        collection_symbol: string::String,
        admin : address,
        receiver: address , 
        royality : u64,
        ctx: &mut TxContext,
    ): Collection<T> {
        utils::assert_same_module<OTW, T>();
        create_( receiver ,royality,admin,collection_name,collection_symbol ,ctx)
    }

    fun create_<T>( 
        receiver: address , 
        royality : u64,
        admin : address,
        collection_name: string::String,
        collection_symbol: string::String,
        ctx: &mut TxContext
        ): Collection<T> {
        let id = object::new(ctx);

        event::emit(MintCollectionEvent {
            collection_id: object::uid_to_inner(&id),
            type_name: type_name::get<T>(),
        });

        Collection { id,receiver , royality ,collection_name , collection_symbol,admin }
    }

    public fun set_royality<OTW: drop, T>(
        _witness: OTW,
        collection:&mut Collection<T> ,
        royality: u64 , 
        ctx: &mut TxContext
        ){
        utils::assert_same_module<OTW, T>();
        assert!(collection.admin == sender(ctx), 0);
             collection.royality = royality;
    }

    public fun set_collection_name<OTW: drop, T>(
        _witness: OTW,
        collection:&mut Collection<T> ,
        collection_name: String , 
        ctx: &mut TxContext
        ){
        utils::assert_same_module<OTW, T>();
        assert!(collection.admin == sender(ctx), 0);
         collection.collection_name = collection_name;
    }
     
    public fun set_collection_symbol<OTW: drop, T>(
        _witness: OTW,
        collection:&mut Collection<T> ,
        collection_symbol: String , 
        ctx: &mut TxContext
        ){
        utils::assert_same_module<OTW, T>();
        assert!(collection.admin == sender(ctx), 0);
         collection.collection_symbol = collection_symbol;
    }
     
    public fun set_royality_receiver<OTW: drop, T>(
        _witness: OTW,
        collection:&mut Collection<T> ,
        receiver: address , 
        ctx: &mut TxContext
        ){
        utils::assert_same_module<OTW, T>();
        assert!(collection.admin == sender(ctx), 0);
         collection.receiver = receiver;
    }
    public fun change_admin<OTW: drop, T>(
        _witness: OTW,
        collection:&mut Collection<T> ,
        new_admin: address , 
        ctx: &mut TxContext
        ){
        utils::assert_same_module<OTW, T>();
        assert!(collection.admin == sender(ctx), 0);
         collection.admin = new_admin;
    }



    public fun get_receiver_address<C>(collection: &Collection<C>): address {
        collection.receiver
    }
     public fun get_royality_percentage<C>(collection: &Collection<C>): u64 {
        collection.royality
    }

  
}
