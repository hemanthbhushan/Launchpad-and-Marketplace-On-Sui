module moonpad::oasisx{
    use std::string::{String,utf8};
    use sui::tx_context::{TxContext,sender};
    use sui::url;
    use sui::transfer;
    use sui::package;
    use sui::display;
    use moonpad::nft::{Self ,Nft};
    use moonpad::witness;
    use moonpad::frozen_publisher;

    struct CREATOR has drop {}
    struct OASISX has drop {}
    struct Witness has drop {}
      

      fun init(otw: OASISX,ctx: &mut TxContext){
          let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"image_url"),
            utf8(b"description"),
            utf8(b"project_url"),
            utf8(b"creator"),
        ];

        let values = vector[
            // For `name` we can use the `Hero.name` property
            utf8(b"{name}"),
            // For `link` we can build a URL using an `id` property
            utf8(b"https://sui-heroes.io/hero/{id}"),
            // For `image_url` we use an IPFS template + `img_url` property.
            utf8(b"ipfs://{url}"),
            // Description is static for all `Hero` objects.
            utf8(b"A true Hero of the Sui ecosystem!"),
            // Project URL is usually static
            utf8(b"https://sui-heroes.io"),
            // Creator field can be any
            utf8(b"Unknown Sui Fan")
        ];

        // Claim the `Publisher` for the package!
  
        let publisher = package::claim(otw, ctx);
        let frozen_publisher = frozen_publisher::new(publisher , ctx);
        let witness = witness::from_witness<CREATOR,Witness>(Witness{});

        let display  = nft::new_display<CREATOR>(witness , &frozen_publisher , ctx);

        display::add_multiple<Nft<CREATOR>>(&mut display, keys, values);
        display::update_version(&mut display);
        frozen_publisher::public_freeze_object(frozen_publisher);
        transfer::public_transfer(display, sender(ctx))
    }

    public entry fun create(name: String , url: vector<u8>,ctx: &mut TxContext){

        let witness = witness::from_witness<CREATOR,Witness>(Witness{});
        let minted  = nft::new<CREATOR>(witness ,name , url::new_unsafe_from_bytes(url),ctx );
       
        transfer::public_transfer(minted,sender(ctx))
    }

}