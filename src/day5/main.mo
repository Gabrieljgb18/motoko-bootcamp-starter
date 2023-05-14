import HashMap "mo:base/HashMap";
import Principal "mo:base/Principal";
import Hash "mo:base/Hash";
import Error "mo:base/Error";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Int "mo:base/Int";
import Timer "mo:base/Timer";
import Debug "mo:base/Debug";
import Buffer "mo:base/Buffer";
import Iter "mo:base/Iter";

import Ic "Ic";
import HTTP "Http";
import Type "Types";

actor class Verifier() {
  type StudentProfile = Type.StudentProfile;

  //Counter Profile
  var counterProfile = 0;

  // Definition HashMap
  stable var entries : [(Principal, StudentProfile)] = [];
  let iter = entries.vals();

  let studentProfileStore : HashMap.HashMap<Principal, StudentProfile> = HashMap.fromIter<Principal, StudentProfile>(iter, 1, Principal.equal, Principal.hash);

  // Saver funtions

  system func preupgrade() {
    entries := Iter.toArray(studentProfileStore.entries());
  };

  system func postupgrade() {
    entries := [];
  };

  // STEP 1 - BEGIN
  public shared ({ caller }) func addMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    if (Principal.isAnonymous(caller)) {
      return #err ("Profile can't be empty"); 
    };
    studentProfileStore.put(caller, profile);
    return #ok ();
  };

  public shared ({ caller }) func seeAProfile(p : Principal) : async Result.Result<StudentProfile, Text> {
    switch (studentProfileStore.get(p)) {
      case (null) {
        return #err("srudent not found");
      };
      case (?profile) {
        return #ok profile;
      };
    };
  };

  public shared ({ caller }) func updateMyProfile(profile : StudentProfile) : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {
        return #err("Student not found");
      };
      case (?profileItem) {
        studentProfileStore.put(caller, profile);
        return #ok();
      };
    };
  };

  public shared ({ caller }) func deleteMyProfile() : async Result.Result<(), Text> {
    switch (studentProfileStore.get(caller)) {
      case (null) {
        return #err("Student not found");
      };
      case (?profileItem) {
        studentProfileStore.delete(caller);
        return #ok();
      };
    };
  };
  // STEP 1 - END

  // STEP 2 - BEGIN
  type calculatorInterface = Type.CalculatorInterface;
  public type TestResult = Type.TestResult;
  public type TestError = Type.TestError;

  // Interface Studente Caculator
  public func test(canisterId : Principal) : async TestResult {
    let studentCalculator = actor (Principal.toText(canisterId)) : actor {
      add : shared (n : Int) -> async Int;
      sub : shared (n : Int) -> async Int;
      reset : shared () -> async Int;
    };
    try {
      let v1 : Int = await studentCalculator.reset();
      if (v1 != 0) {
        return #err(#UnexpectedValue("The result reset() is not correct"));
      };

      let v2 : Int = await studentCalculator.add(1);
      if (v2 != 1) {
        return #err(#UnexpectedValue("The result add() is not correct"));
      };

      let v3 : Int = await studentCalculator.sub(1);
      if (v3 != 0) {
        return #err(#UnexpectedValue("The result sub() is not correct"));
      };

      return #ok();
    } catch (e) {
      return #err(#UnexpectedError("Some is wrong, check your code"));
    };
  };

  // STEP - 2 END

  // STEP 3 - BEGIN
  // NOTE: Not possible to develop locally,
  // as actor "aaaa-aa" (aka the IC itself, exposed as an interface) does not exist locally
  public func verifyOwnership(canisterId : Principal, p : Principal) : async Bool {
    
    let controllers = await Ic.getCanisterControllers(canisterId);

    var isOwner : ?Principal = Array.find<Principal>(controllers, func prin = prin == p);

    if (isOwner != null) {
      return true;
    };

    return false;
  };

  // STEP 3 - END

  // STEP 4 - BEGIN
  public shared ({ caller }) func verifyWork(canisterId : Principal, p : Principal) : async Result.Result<(), Text> {
    try {
      let studentOk = await verifyOwnership(canisterId, p);
      if (not studentOk) {
        return #err("Student not found");
      };
      let calculatorOk = await test(canisterId);
      if (calculatorOk != #ok) {
        return #err("Incorrect implementation");
      };    
      switch (studentProfileStore.get(p)) {
        case null {
          return #err("The principal do not correspond to a registered student");
        };
        case (?profile) {
          var updatedStudent = {
            name = profile.name;
            team = profile.team;
            graduate = true;
          };
          ignore studentProfileStore.replace(p, updatedStudent);
          return #ok();
        };
      };
    } catch (e) {
      return #err("Not veirificate");
    };
  };
  // STEP 4 - END

};
