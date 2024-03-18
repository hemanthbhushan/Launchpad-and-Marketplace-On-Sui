module launchpad::moonpad {
    use std::string::String;
    use std::ascii;
    use std::option::{Self, Option};
    use std::vector;
    use sui::tx_context::{TxContext, sender};
    use sui::sui::SUI;
    use sui::clock::{Self, Clock};
    use sui::url;
    use sui::transfer;
    use sui::vec_map::{Self, VecMap};
    use sui::object::{Self, ID, UID};
    use sui::balance::{Self, Balance};
    use sui::table::{Self, Table};
    use sui::dynamic_object_field as dof;
    use sui::coin::{Self,Coin};
    use common::nft::{Self, Nft};
    use common::collection::{Self, Collection};
 
//Nft cllection name
    struct CREATOR has drop {}
    struct Witness has drop {}

    struct LaunchPadCap has key {
        id: UID
    }

    struct NFTPresaleInfo has store {
        start_time: u64,
        end_time: u64,
        current_minted: u64,
        price_per_nft: u64,
        whitelisted_buyers: vector<address>,
        max_nfts: u64,
        is_paused: bool
    }

    struct MintCap has key {
        id: UID,
        for_collection_id: ID,
        max_mintable: u64,
        current_minted: u64,
    }

    struct LaunchPadData has key {
        id: UID,
        admin: address,
        price_per_nft: u64,
        max_nft_per_user : u64,
        co_owners: Option<VecMap<address, u16>>,
        user_purchase_counts: Table<address, u64>,
        total_funds_collected: Balance<SUI>,
        presale: Option<NFTPresaleInfo>,
        is_public_sale_paused: bool , 
        nft_ids : vector<ID> ,
        total_nfts_deposited : u64
    }

    fun init(ctx: &mut TxContext) {
        transfer::transfer(LaunchPadCap { id: object::new(ctx) }, sender(ctx))
    }
    
   #[lint_allow(share_owned)]
    public entry fun initiate_launchpad(
        launchpad_cap: LaunchPadCap,
        collection_name : String,
        collection_symbol : String,
        receiver: address , 
        royality : u64,
        public_nft_price: u64,
        max_nft_per_user: u64,
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
                for_collection_id: object::id(&collection),
                max_mintable: max_nft_limt,
                current_minted: 0,
        };

        let launchpadData = LaunchPadData {
            id: object::new(ctx),
            admin: sender(ctx),
            price_per_nft: public_nft_price,
            max_nft_per_user,
            co_owners: option::none(),
            user_purchase_counts: table::new(ctx),
            total_funds_collected: balance::zero<SUI>(),
            presale: option::none(),
            is_public_sale_paused: true,
            nft_ids : vector::empty<ID>() ,
            total_nfts_deposited : 0
        };

        transfer::public_share_object(collection);
        transfer::share_object(launchpadData);
        transfer::transfer(mint_cap , sender(ctx))

    }

    public entry fun set_presale(
        launchpad_data: &mut LaunchPadData,
        start_time: u64,
        end_time: u64,
        price_per_nft: u64,
        whitelisted_buyers: vector<address>,
        max_nfts: u64,
        ctx: &mut TxContext
    ) {

        assert!(launchpad_data.admin == sender(ctx), 0);
        assert!(option::is_none(&launchpad_data.presale),00);
        let presale_info = NFTPresaleInfo {
            start_time,
            end_time,
            current_minted: 0,
            price_per_nft,
            whitelisted_buyers,
            max_nfts,
            is_paused: true
        };

        option::fill(&mut launchpad_data.presale, presale_info);
    }

    public entry fun launch_pre_sale(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        assert!(vector::length(&launchpad_data.nft_ids) > 0, 0 );
        option::borrow_mut(&mut launchpad_data.presale).is_paused = false
    }

    public entry fun launch_public_sale(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        assert!(vector::length(&launchpad_data.nft_ids) > 0, 0 );
        launchpad_data.is_public_sale_paused = false
    }

    public entry fun set_co_owners(
        launchpad_data: &mut LaunchPadData,
        new_owners: vector<address>,
        owner_shares: vector<u16>,
        ctx: &mut TxContext
    ) {
        let admin = sender(ctx);
        assert!(launchpad_data.admin == admin, 0);
        let len : u64 = vector::length(&new_owners);
        assert!(len > 0, 00);
        assert!(len == vector::length(&owner_shares), 00);

        let i = 0;
        if (option::is_none(&launchpad_data.co_owners)) {
            let co_owners_temp = vec_map::empty<address, u16>();
             vec_map::insert(&mut co_owners_temp, admin, 10_000);
            while (i < len) {
                let owner_addr = vector::pop_back(&mut new_owners);
                let owner_share = vector::pop_back(&mut owner_shares);
                let creator_share =  vec_map::get_mut(&mut co_owners_temp, &admin);
                *creator_share = *creator_share - owner_share;
                vec_map::insert(&mut co_owners_temp, owner_addr, owner_share);
                i = i + 1
            };
            option::fill(&mut launchpad_data.co_owners, co_owners_temp)
        } else {
            while (i < len) {
                let co_owners_temp = option::borrow_mut(&mut launchpad_data.co_owners);
                let creator_share =  vec_map::get_mut(co_owners_temp, &admin);

                let owner_addr_temp = vector::pop_back(&mut new_owners);
                let owner_percent_temp = vector::pop_back(&mut owner_shares);

                 *creator_share = *creator_share - owner_percent_temp;
                 assert!(*creator_share > 0,0);
                let co_owners_temp = option::borrow_mut(&mut launchpad_data.co_owners);
                vec_map::insert(co_owners_temp, owner_addr_temp, owner_percent_temp);
                i = i + 1
            }
        };
        let shares = option::borrow(&launchpad_data.co_owners);
        assert_total_shares(shares)
    }

    public entry fun increase_co_owner_percentage(
        launchpad_data: &mut LaunchPadData,
        owner_addr: address,
        additional_share: u16,
        ctx: &mut TxContext
    ) {
        let admin = sender(ctx);
        assert!(launchpad_data.admin == admin, 0);
        let co_owners_temp = option::borrow_mut(&mut launchpad_data.co_owners);
        let creator_share =  vec_map::get_mut(co_owners_temp, &admin);
        assert!(*creator_share > additional_share,0);
        *creator_share = *creator_share - additional_share;
        let owner_share = vec_map::get_mut(co_owners_temp, &owner_addr);
        *owner_share = *owner_share + additional_share;
        
    }

    public entry fun decrease_co_owner_percentage(
        launchpad_data: &mut LaunchPadData,
        owner_addr: address,
        decrease_share: u16,
        ctx: &mut TxContext
    ) {
        let admin = sender(ctx);
        assert!(launchpad_data.admin == admin, 0);
        let co_owners_temp = option::borrow_mut(&mut launchpad_data.co_owners);
        
        let owner_share =  vec_map::get_mut(co_owners_temp, &owner_addr);
        assert!(*owner_share >= decrease_share ,00);
        *owner_share = *owner_share - decrease_share;
        if(*owner_share == 0){
            let (_,_) = vec_map::remove(co_owners_temp , &owner_addr);
        };
        let creator_share =  vec_map::get_mut(co_owners_temp, &admin);
        *creator_share = *creator_share + decrease_share;
       
    }

    public entry fun remove_all_co_owners(launchpad_data: &mut LaunchPadData, ctx: &mut TxContext) {
        assert!(launchpad_data.admin == sender(ctx), 0);
        let _ = option::extract(&mut launchpad_data.co_owners);
    }
    


    public entry fun mint_nft_and_store_admin(
        launchpad_data: &mut LaunchPadData , 
        mint_cap : &mut MintCap,
        name: String,
        url: ascii::String,
        description: String,
        self_transfer : bool,
        ctx: &mut TxContext
        ){
           assert!(launchpad_data.admin == sender(ctx), 0);
           assert!(mint_cap.current_minted + 1 <= mint_cap.max_mintable , 00 );   
           let nft = nft::new<Witness , CREATOR>(Witness {},name , url::new_unsafe(url) , description, ctx);

           if(!self_transfer){
             let nft_id = object::id(&nft);

            vector::push_back(&mut launchpad_data.nft_ids, nft_id);
            launchpad_data.total_nfts_deposited = launchpad_data.total_nfts_deposited + 1;
            
            dof::add(&mut launchpad_data.id, nft_id, nft) 
           }else{
             transfer::public_transfer(nft , sender(ctx))

           };
           mint_cap.current_minted = mint_cap.current_minted + 1 ;
             
    }

 
     public entry fun buy_nft(
        launchpad_data: &mut LaunchPadData , 
        nft_id : ID ,
        paid : &mut Coin<SUI> ,
        ctx: &mut TxContext
        ){
           assert!(!launchpad_data.is_public_sale_paused , 00);
           assert!(launchpad_data.total_nfts_deposited > 0, 0);
           let buyer = sender(ctx);
           assert!(*table::borrow(&launchpad_data.user_purchase_counts , buyer) <= launchpad_data.max_nft_per_user , 00);
           let price_per_nft = launchpad_data.price_per_nft;
           if(!table::contains(&launchpad_data.user_purchase_counts , buyer)){
              table::add(&mut launchpad_data.user_purchase_counts , buyer , 0);
           };

           let buyer_purchase_count  = table::borrow_mut(&mut launchpad_data.user_purchase_counts , buyer);
           *buyer_purchase_count = *buyer_purchase_count + 1;
           take_fee_and_transfer(launchpad_data ,nft_id, price_per_nft , paid ,ctx);
    }

     public entry fun buy_nft_pre_sale(
        launchpad_data: &mut LaunchPadData , 
        nft_id : ID ,
        paid : &mut Coin<SUI> ,
        clock: &Clock,
        ctx: &mut TxContext
        ){
           assert!(option::is_some(&launchpad_data.presale), 0);
           assert!(launchpad_data.total_nfts_deposited > 0, 0);

           let presale_data = option::borrow_mut(&mut launchpad_data.presale);
           assert!(!presale_data.is_paused, 0);

           let buyer = sender(ctx);
           assert!(*table::borrow(&launchpad_data.user_purchase_counts , buyer) + 1 <= launchpad_data.max_nft_per_user , 00);

           let currentTime = clock::timestamp_ms(clock);
           assert!(presale_data.end_time >= currentTime, 0);
           assert!(presale_data.start_time <= currentTime, 0);

            let buyer_purchase_count  = table::borrow_mut(&mut launchpad_data.user_purchase_counts , buyer);
           *buyer_purchase_count = *buyer_purchase_count + 1;
           take_fee_and_transfer(launchpad_data ,nft_id,presale_data.price_per_nft , paid ,ctx) 
    }

    public entry fun redeem_funds(
        launchpad_data: &mut LaunchPadData , 
        ctx: &mut TxContext
    ){
         assert!(launchpad_data.admin == sender(ctx), 0);   
         assert!(balance::value(&launchpad_data.total_funds_collected) > 0, 0);
        let total_funds_collected = balance::value(&launchpad_data.total_funds_collected);

         if(option::is_some(&launchpad_data.co_owners)){
            let co_owners = option::borrow_mut(&mut launchpad_data.co_owners);
            let len =  vec_map::size(co_owners);
            let i = 0;
             while (i < len){
                 let (owner_addr,share) = vec_map::get_entry_by_idx(co_owners , i);
                  let split_amount = total_funds_collected * (*share as u64) /10_000;
                  let balance =  balance::split(&mut launchpad_data.total_funds_collected , split_amount);
                  transfer::public_transfer(coin::from_balance( balance,ctx) , *owner_addr);
                 i = i+ 1   
             };
         }else{
            transfer::public_transfer(coin::from_balance( balance::withdraw_all(&mut launchpad_data.total_funds_collected),ctx) , sender(ctx))
         }
    }

    #[lint_allow(self_transfer)]
    fun take_fee_and_transfer(
        launchpad_data: &mut LaunchPadData ,
        nft_id : ID ,
        price_per_item : u64 ,
        paid : &mut Coin<SUI> ,
        ctx: &mut TxContext 
    ){
        assert!(coin::value<SUI>(paid) >= price_per_item , 0);
        let coin =  coin::split<SUI>(paid, price_per_item, ctx);
        coin::put<SUI>( &mut launchpad_data.total_funds_collected, coin);
        let (has , i) =  vector::index_of(&launchpad_data.nft_ids, &nft_id);
        assert!(has, 0);
        let nft_id = vector::swap_remove(&mut launchpad_data.nft_ids ,i );
        launchpad_data.total_nfts_deposited = launchpad_data.total_nfts_deposited - 1;
        let nft : Nft<CREATOR>  =  dof::remove(&mut launchpad_data.id, nft_id) ;
        transfer::public_transfer(nft ,sender(ctx))
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

    fun assert_total_shares(shares: &VecMap<address, u16>) {
        let bps_total = 0;

        if (vec_map::is_empty(shares)) {
            return
        };

        let i = 0;
        while (i < vec_map::size(shares)) {
            let (_, share) = vec_map::get_entry_by_idx(shares, i);
            bps_total = bps_total + *share;
            i = i + 1;
        };

        assert!(bps_total == 10_000, 00);
    }

}
