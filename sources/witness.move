/// Module of the `WitnessGenerator` used for generating authenticating
/// witnesses on demand.
///
/// The OriginByte protocol leverages on a Delegated-Witness pattern which function
/// as an hybrid between the Witness and Publisher pattern. Furthermore, it provides
/// a `WitnessGenerator` which allows for the witness creation to be delegated to
/// other smart contracts/objects defined in modules other than the creator of `T`.
/// In a nutshell, the differences between a Delegated-Witness and a typical Witness are:
///
/// - Deletaged-Witness has copy and it can therefore be easily propated accross
/// a stack of function calls;
/// - Deletaged-Witness is typed, and this in conjunction with the copy ability allows for the
/// reduction of type-reflected assertions that are required to be perfomed accross the call stack
/// - A Delegated-Witness can be created by `Witness {}`, so like the witness its access can be
/// designed by the smart contract that defines `T`;
/// - It can also be created directly through the Publisher object;
/// - It can be generated by a generator object `WitnessGenerator<T>` which has store ability,
/// therefore allowing for witness-creation process to be more flexibly delegated.
module moonpad::witness {
    use sui::package::Publisher;

    use moonpad::utils;

    /// Collection witness generator
    struct WitnessGenerator<phantom T> has store {}

    /// Delegated witness of a generic type. The type `T` can either be
    /// the One-Time Witness of a collection or the type of an NFT itself.
    struct Witness<phantom T> has copy, drop {}

    /// Create a new `WitnessGenerator` from witness
    public fun generator<T, W: drop>(witness: W): WitnessGenerator<T> {
        generator_delegated(from_witness<T, W>(witness))
    }

    /// Create a new `WitnessGenerator` from delegated witness
    public fun generator_delegated<T>(
        _witness: Witness<T>,
    ): WitnessGenerator<T> {
        WitnessGenerator {}
    }

    /// Delegate a delegated witness from arbitrary witness type
    public fun from_witness<T, W: drop>(_witness: W): Witness<T> {
        utils::assert_same_module_as_witness<T, W>();
        Witness {}
    }

    /// Creates a delegated witness from a package publisher.
    /// Useful for contracts which don't support our protocol the easy way,
    /// but use the standard of publisher.
    public fun from_publisher<T>(publisher: &Publisher): Witness<T> {
        utils::assert_publisher<T>(publisher);
        Witness {}
    }

    /// Delegate a collection generic witness
    public fun delegate<T>(_generator: &WitnessGenerator<T>): Witness<T> {
        Witness {}
    }

    // === Test-Only Functions ===

    #[test_only]
    public fun test_dw<T>(): Witness<T> {
        Witness {}
    }
}
