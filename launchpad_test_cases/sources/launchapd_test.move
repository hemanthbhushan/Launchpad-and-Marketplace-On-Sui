#[test_only]
#[allow(unused_function , unused_use)]
module wallet_tests::wallet_test {
    use sui::tx_context::{Self, TxContext};
    // use sui::test_utils;
    use sui::test_scenario::{Self, Scenario};
    use std::debug::print;
    use std::string::utf8;
    use wallet_tests::coin_test::{Self,OTW};
    use std::option;
    use std::vector; // creates currency
    use sui::object::{Self, UID , ID};
    use sui::transfer::{Self , Receiving};
    use sui::coin::{Self,TreasuryCap, Coin};
    use sui::test_utils;
    use std::type_name::{Self as tn, TypeName};

    use launchpad::{Self,LaunchPadCap};

}