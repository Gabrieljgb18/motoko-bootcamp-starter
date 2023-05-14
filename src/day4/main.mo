import TrieMap "mo:base/TrieMap";
import Trie "mo:base/Trie";
import Result "mo:base/Result";
import Text "mo:base/Text";
import Option "mo:base/Option";
import Debug "mo:base/Debug";
import Nat "mo:base/Nat";

import Account "Account";
// NOTE: only use for local dev,
// when deploying to IC, import from "rww3b-zqaaa-aaaam-abioa-cai"
import BootcampLocalActor "BootcampLocalActor";
import Hash "mo:base/Hash";
import Principal "mo:base/Principal";

actor class MotoCoin() {
  public type Account = Account.Account;

  var ledger = TrieMap.TrieMap<Account, Nat>(Account.accountsEqual, Account.accountsHash);

  // Returns the name of the token
  public query func name() : async Text {
    return "MotoCoin";
  };

  // Returns the symbol of the token
  public query func symbol() : async Text {
    return "MOC";
  };

  // Returns the the total number of tokens on all accounts
  public func totalSupply() : async Nat {
    var balance = 0;
    for ((key, value) in ledger.entries()) {
      balance += value;
    };
    return balance;
  };

  // Returns the default transfer fee
  public query func balanceOf(account : Account) : async (Nat) {
    switch (ledger.get(account)) {
      case (null) { 0 };
      case (?fee) { fee };
    };
  };

  // Transfer tokens to another account
  public shared ({ caller }) func transfer(
    from : Account,
    to : Account,
    amount : Nat,
  ) : async Result.Result<(), Text> {
    func balanceOf(account : Account) : Nat {
      switch (ledger.get(account)) {
        case (null) { 0 };
        case (?fee) { fee };
      };
    };
    var balanceFrom : Nat = balanceOf(from);
    var balanceTo : Nat = balanceOf(to);

    if (balanceFrom < amount) {
      return #err("Sender does not have enough tokens.");
    };

    balanceFrom := balanceFrom - amount;
    balanceTo := balanceTo + amount;

    ledger.put(from, balanceFrom);
    ledger.put(to, balanceTo);

    return #ok();
  };

  // Airdrop 1000 MotoCoin to any student that is part of the Bootcamp.
  public func airdrop() : async Result.Result<(), Text> {
    /* let studentsBoot  = actor ("rww3b-zqaaa-aaaam-abioa-cai") : actor {
      getAllStudentsPrincipal : shared () -> async [Principal];
    }; */

    let studentsBoot = await BootcampLocalActor.BootcampLocalActor();

    let students = await studentsBoot.getAllStudentsPrincipal();

    for ((principal) in students.vals()) {
      let newAccount = { owner = principal; subaccount = null };
      ledger.put(newAccount, 100);
    };
    return #ok();
  };
};
