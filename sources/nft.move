/// Module defining a wrapper `NFT` type
module moonpad::nft {
    use std::ascii;
    use std::string;
    use std::type_name;

    use sui::url::Url;
    use sui::event;
    use sui::display::Display;
    use sui::dynamic_field as df;
    use sui::object::{Self, ID, UID};
    use sui::tx_context::TxContext;

    use moonpad::witness::Witness as DelegatedWitness;
    use moonpad::frozen_publisher::{Self, FrozenPublisher};
  
    /// Witness used to authorize collection creation
    struct Witness has drop {}


    struct Nft<phantom C> has key, store {
        id: UID,
        name: string::String,
        url: Url,
    }

    struct MintNftEvent has copy, drop {
        nft_id: ID,
        nft_type: ascii::String,
    }

    fun new_<C>(
        name: string::String,
        url: Url,
        ctx: &mut TxContext,
    ): Nft<C> {
        let id = object::new(ctx);

        event::emit(MintNftEvent {
            nft_id: object::uid_to_inner(&id),
            nft_type: type_name::into_string(type_name::get<C>()),
        });

        Nft { id, name, url }
    }


    public fun new<C>(
        _witness: DelegatedWitness<C>,
        name: string::String,
        url: Url,
        ctx: &mut TxContext,
    ): Nft<C> {
        new_(name, url, ctx)
    }

    public entry fun delete<C>(nft: Nft<C>) {
        let Nft { id, name: _, url: _ } = nft;
        object::delete(id);
    }


    public fun name<C>(nft: &Nft<C>): &string::String {
        &nft.name
    }

    /// Returns `Nft` URL
    public fun url<C>(nft: &Nft<C>): &Url {
        &nft.url
    }

 
    public fun set_name<C>(
        _witness: DelegatedWitness<C>,
        nft: &mut Nft<C>,
        name: string::String,
    ) {
        nft.name = name
    }

    public fun set_url<C>(
        _witness: DelegatedWitness<C>,
        nft: &mut Nft<C>,
        url: Url,
    ) {
        nft.url = url
    }

   // === Display standard ===

    /// Creates a new `Display` with some default settings.
    public fun new_display<C>(
        _witness: DelegatedWitness<C>,
        pub: &FrozenPublisher,
        ctx: &mut TxContext,
    ): Display<Nft<C>> {
        let display =
            frozen_publisher::new_display<Witness, Nft<C>>(Witness {}, pub, ctx);

        display
    }


    // === Test helpers ===

    #[test_only]
    /// Create `Nft` without access to `MintCap` or derivatives
    public fun test_mint<C>(ctx: &mut TxContext): Nft<C> {
        new_(std::string::utf8(b""), sui::url::new_unsafe_from_bytes(b""), ctx)
    }
}
