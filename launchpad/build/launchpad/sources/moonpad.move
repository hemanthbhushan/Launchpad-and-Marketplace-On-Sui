module launchpad::moonpad{
    use std::string::{String,utf8};
    use std::option::{Self,Option};
    use sui::tx_context::{TxContext,sender};
     use sui::sui::SUI;
    use sui::url;
    use sui::transfer;
    use sui::package;
    use sui::display::{Self,Display};
    use sui::vec_map::{Self ,VecMap};
    use sui::object::{Self , ID ,UID};
    use sui::balance::{Self ,Balance};
    use sui::table::{Self ,Table};
    use common::nft::{Self ,Nft};
    use common::witness;
    use common::frozen_publisher;
    use common::collection::{Self ,Collection};

    struct CREATOR has drop {}
    struct MOONPAD has drop {}
    struct Witness has drop {}

    struct NFTPresaleInfo has store{
        start_time: u64,
        expired_time: u64,
        nft_per_user: u64,
        current_nft: u64,
        price_per_item: u64,
        //this can be used for checking user whitlisted 
        whitelisted_users : vector<address> ,
        max_nfts: u64,
    }
    
    struct MintCap has key {
        id : UID , 
        collection_id: ID,
        max: u64,
        current: u64,
    }

     struct LaunchPadData has key {
        id  :UID ,
        price : u64,
        nft_per_user: u64,
        multi_owners : Option<VecMap<address , u64>> ,
        purchases: Table<address, u64> , 
        fund_collected : Balance<SUI> ,
        presale : Option<NFTPresaleInfo> ,
        public_sale_paused : bool
    }  

      fun init(otw: MOONPAD,ctx: &mut TxContext){
          let keys = vector[
            utf8(b"name"),
            utf8(b"link"),
            utf8(b"url"),
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
            utf8(b"{description}"),
            // Project URL is usually static
            utf8(b"https://sui-heroes.io"),
            // Creator field can be any
            utf8(b"Unknown Sui Fan")
        ];
    
         let witness = witness::from_witness<CREATOR,Witness>(Witness{});
        let collection = collection::create<CREATOR>(
                            witness , 
                            sender(ctx),
                            10000, 
                            utf8(b"CREATOR"),
                            utf8(b"CRT") , 
                            ctx);

        // Claim the `Publisher` for the package!
  
        // let publisher = package::claim(otw, ctx);
        // let frozen_publisher = frozen_publisher::new(publisher , ctx);  
        // let witness = witness::from_witness<CREATOR,Witness>(Witness{});
        // let display  = nft::new_display<CREATOR>(witness , &frozen_publisher , ctx);
          
        // display::add_multiple<Nft<CREATOR>>(&mut display, keys, values);
        // display::update_version(&mut display);
        // frozen_publisher::public_freeze_object(frozen_publisher);
        // transfer::public_transfer(display, sender(ctx));
        transfer::public_share_object(collection)
    }

    public entry fun create(name: String , url: vector<u8>, description : String,ctx: &mut TxContext){

        let witness = witness::from_witness<CREATOR,Witness>(Witness{});
        let minted  = nft::new<CREATOR>(witness ,name , url::new_unsafe_from_bytes(url),description ,ctx );
       
        transfer::public_transfer(minted,sender(ctx))
    }



    

}