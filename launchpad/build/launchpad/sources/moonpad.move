module launchpad::moonpad {
    use std::string::{String, utf8};
    use std::ascii;
    use std::option::{Self, Option};
    use std::vector;
    use sui::tx_context::{TxContext, sender};
    use sui::sui::SUI;
    use sui::url;
    use sui::transfer;
    use sui::package;
    use sui::display::{Self, Display};
    use sui::vec_map::{Self, VecMap};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::coin::{Self,Coin};
    use common::nft::{Self, Nft};
    use common::witness;
    use common::frozen_publisher;
    use common::collection::{Self, Collection};
 

    struct CREATOR has drop {}
    struct Witness has drop {}
    // struct MOONPAD has drop {}

    struct LaunchPadCap has key {
        id: UID
    }

    struct NFTPresaleInfo has store {
        start_time: u64,
        expired_time: u64,
        current_nft: u64,
        price_per_item: u64,
        whitelisted_users: vector<address>,
        max_nfts: u64,
        pre_sale_paused: bool
    }

    struct MintCap has key {
        id: UID,
        for: ID,
        max: u64,
        current: u64,
    }

    struct LaunchPadData has key {
        id: UID,
        admin: address,
        price: u64,
        nft_per_user : u64,
        multi_owners: Option<VecMap<address, u64>>,
        purchases: Table<address, u64>,
        fund_collected: Balance<SUI>,
        presale: Option<NFTPresaleInfo>,
        public_sale_paused: bool , 
        nfts : vector<ID> ,
        total_deposited : u64
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(LaunchPadCap { id: object::new(ctx) }, sender(ctx))
    }

    public entry fun initiate_launchpad(
        launchpad_cap: LaunchPadCap,
        collection_name : String,
        collection_symbol : String,
        admin : address,
        receiver: address , 
        royality : u64,
        public_nft_price: u64,
        nft_per_user: u64,
        max_nft_limt: u64,
        ctx: &mut TxContext
    ) {
        let LaunchPadCap { id } = launchpad_cap;
        object::delete(id);
        let collection = collection::create<Witness ,CREATOR>(
            Witness{},
            collection_name ,
            collection_symbol ,
            sender(ctx),
            receiver , 
            royality,
            ctx
        );

        let mint_cap = MintCap { 
                id: object::new(ctx) , 
                for: object::id(&collection),
                max: max_nft_limt,
                current: 0,
        };

        let launchpadData = LaunchPadData {
            id: object::new(ctx),
            admin: sender(ctx),
            price: public_nft_price,
            nft_per_user,
            multi_owners: option::none(),
            purchases: table::new(ctx),
            fund_collected: balance::zero<SUI>(),
            presale: option::none(),
            public_sale_paused: true,
            nfts : vector::empty<ID>() ,
            total_deposited : 0
        };

        transfer::public_share_object(collection);
        transfer::share_object(launchpadData);
        transfer::share_object(mint_cap)

    }

    public entry fun set_presale(
        launchpad_data: &mut LaunchPadData,
        start_time: u64,
        expired_time: u64,
        price_per_item: u64,
        whitelisted_users: vector<address>,
        max_nfts: u64,
        ctx: &mut TxContext
    ) {
        assert!(option::is_none(&launchpad_data.presale),00);
        let presale_info = NFTPresaleInfo {
            start_time,
            expired_time,
            current_nft: 0,
            price_per_item,
            whitelisted_users,
            max_nfts,
            pre_sale_paused: true
        };

        option::fill(&mut launchpad_data.presale, presale_info);
    }

    public entry fun launch_pre_sale(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        option::borrow_mut(&mut launchpad_data.presale).pre_sale_paused = false
    }

    public entry fun launch_public_sale(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        launchpad_data.public_sale_paused = false
    }

    public entry fun set_multiple_owners(
        launchpad_data: &mut LaunchPadData,
        owner_addr: vector<address>,
        owner_percentage: vector<u64>,
        ctx: &mut TxContext
    ) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        let len = vector::length(&owner_addr);
        assert!(len > 0, 00);
        assert!(len == vector::length(&owner_percentage), 00);
        let i = 0;
        let total_percentage = 0;

        while (i < len) {
            total_percentage =total_percentage + *vector::borrow(&owner_percentage , i);
        };
        // Ensure total percentage equals 100
        assert!(total_percentage == 100, 100);

        let i = 0;
        if (option::is_none(&launchpad_data.multi_owners)) {
            let multi_owners_temp = vec_map::empty<address, u64>();
            while (i < len) {
                let owner_addr_temp = vector::pop_back(&mut owner_addr);
                let owner_percent_temp = vector::pop_back(&mut owner_percentage);
                vec_map::insert(&mut multi_owners_temp, owner_addr_temp, owner_percent_temp);
                i = i + 1
            };
            option::fill(&mut launchpad_data.multi_owners, multi_owners_temp)
        } else {
            while (i < len) {
                let owner_addr_temp = vector::pop_back(&mut owner_addr);
                let owner_percent_temp = vector::pop_back(&mut owner_percentage);

                let multi_owners_temp = option::borrow_mut(&mut launchpad_data.multi_owners);
                vec_map::insert(multi_owners_temp, owner_addr_temp, owner_percent_temp);
                i = i + 1
            }
        }
    }

    public entry fun edit_multi_owners_percentage(
        launchpad_data: &mut LaunchPadData,
        owner_addr: address,
        owner_percentage: u64,
        ctx: &mut TxContext
    ) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        let multi_owners_temp = option::borrow_mut(&mut launchpad_data.multi_owners);
        let val = vec_map::get(multi_owners_temp, &owner_addr);
        val = &mut owner_percentage;
    }

    public entry fun remove_multi_owner(launchpad_data: &mut LaunchPadData, owner_addr: address, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        let multi_owners_temp = option::borrow_mut(&mut launchpad_data.multi_owners);
        let (_, _) = vec_map::remove(multi_owners_temp, &owner_addr);
    }

    public entry fun remove_all_multi_owner(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        let _ = option::extract(&mut launchpad_data.multi_owners);
    }
    

    // /// Redeems NFT from `Warehouse` sequentially
    // ///
    // /// #### Panics
    // ///
    // /// Panics if `Warehouse` is empty.
    // public fun redeem_nft<T: key + store>(
    //     warehouse: &mut Warehouse<T>,
    // ): T {
    //     assert!(warehouse.total_deposited > 0, EEmpty);

    //     let nft_id = dyn_vector::pop_back(&mut warehouse.nfts);
    //     warehouse.total_deposited = warehouse.total_deposited - 1;

    //     dof::remove(&mut warehouse.id, nft_id)
    // }

    public entry fun mint_nft_and_store_admin(
        launchpad_data: &mut LaunchPadData , 
        mint_cap : &mut MintCap,
        name: String,
        url: ascii::String,
        description: String,
        ctx: &mut TxContext
        ){
           assert!(launchpad_data.admin == sender(ctx), 0);   
           let nft = nft::new<Witness , CREATOR>(Witness {},name , url::new_unsafe(url) , description, ctx);
           let nft_id = object::id(&nft);

            vector::push_back(&mut launchpad_data.nfts, nft_id);
            launchpad_data.total_deposited = launchpad_data.total_deposited + 1;

            dof::add(&mut launchpad_data.id, nft_id, nft)    
    }
     public entry fun buy_nft(
        launchpad_data: &mut LaunchPadData , 
        nft_id : ID ,
        paid : &mut Coin<SUI> ,
        ctx: &mut TxContext
        ){
           assert!(launchpad_data.admin == sender(ctx), 0);   
           assert!(launchpad_data.total_deposited > 0, 0);

           let coin =  coin::split<SUI>(paid, launchpad_data.price, ctx);
           coin::put<SUI>( &mut launchpad_data.fund_collected, coin);
           let (has , i) =  vector::index_of(&mut launchpad_data.nfts, &nft_id);
           assert!(has, 0);
           let nft_id = vector::swap_remove(&mut launchpad_data.nfts ,i );
           launchpad_data.total_deposited = launchpad_data.total_deposited - 1;

           let nft : Nft<CREATOR>  =  dof::remove(&mut launchpad_data.id, nft_id) ;
           transfer::public_transfer(nft ,sender(ctx))
    }

    public entry fun redeem_funds(
        launchpad_data: &mut LaunchPadData , 
        ctx: &mut TxContext
    ){
         assert!(launchpad_data.admin == sender(ctx), 0);   
         assert!(balance::value(&launchpad_data.fund_collected) > 0, 0);
        let total_funds_collected_temp = balance::value(&launchpad_data.fund_collected);

         if(option::is_some(&launchpad_data.multi_owners)){
            let multi_owners = option::borrow_mut(&mut launchpad_data.multi_owners);
            let len =  vec_map::size(multi_owners);
            let i = 0;
             while (i < len){
                 let (owner_addr,percent) = vec_map::get_entry_by_idx(multi_owners , i);
                  let split_amount = total_funds_collected_temp * *percent /100;
                  let balance =  balance::split(&mut launchpad_data.fund_collected , split_amount);
                  transfer::public_transfer(coin::from_balance( balance,ctx) , sender(ctx));
                 i = i+ 1   
             };
          
         }else{
            transfer::public_transfer(coin::from_balance( balance::withdraw_all(&mut launchpad_data.fund_collected),ctx) , sender(ctx))
         }
       
    }


    public entry fun set_royality<T>(collection: &mut Collection<T>, royality: u64, ctx: &mut TxContext) {
        collection::set_royality<Witness , T>( Witness{}, collection, royality, ctx);
    }

    public entry fun set_collection_name<T>(collection: &mut Collection<T>, collection_name: String, ctx: &mut TxContext) {
        collection::set_collection_name<Witness , T>( Witness{},collection, collection_name, ctx);
    }

    public entry fun set_collection_symbol<T>(collection: &mut Collection<T>, collection_symbol: String, ctx: &mut TxContext) {
        collection::set_collection_symbol<Witness , T>( Witness{},collection, collection_symbol, ctx);
    }

    public entry fun set_royality_receiver<T>(collection: &mut Collection<T>, receiver: address, ctx: &mut TxContext) {
        collection::set_royality_receiver<Witness , T>( Witness{},collection, receiver, ctx);
    }

    public entry fun change_admin<T>(collection: &mut Collection<T>, new_admin: address, ctx: &mut TxContext) {
        collection::change_admin<Witness , T>( Witness{},collection, new_admin, ctx);
    }

}
