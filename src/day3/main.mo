import Type "Types";
import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Iter "mo:base/Iter";
import HashMap "mo:base/HashMap";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Principal "mo:base/Principal";
import Order "mo:base/Order";
import Option "mo:base/Option";

actor class StudentWall() {
  type Message = Type.Message;
  type Content = Type.Content;
  type Survey = Type.Survey;
  type Answer = Type.Answer;
  type Order = Order.Order;

  // Auxiliar Funtion Hash Nat --> Text
  func _NatToHash (x : Nat) : Hash.Hash{
    Text.hash(Nat.toText(x));
  };

  //Messaje count
  var messageId : Nat = 0;

  //Wall Container
  var wall = HashMap.HashMap<Nat, Message>(1, Nat.equal, _NatToHash);

  // Add a new message to the wall
  public shared ({ caller }) func writeMessage(c : Content) : async Nat {
    messageId := messageId + 1;
    let message : Message = {
      content = c;
      vote = 0;
      creator = caller;
    };
    wall.put(messageId, message);
    return messageId;
    };
  

  // Get a specific message by ID
  public shared query func getMessage(messageId : Nat) : async Result.Result<Message, Text> {
    switch(wall.get(messageId)){
      case(null){return #err ("messageId not found")};
      case(?messageFound){
        return #ok (messageFound);
      }
    }
  };

  // Update the content for a specific message by ID
  public shared ({ caller }) func updateMessage(messageId : Nat, c : Content) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err ("messageId not found")};
      case(?messageItem){
        if(messageItem.creator != caller){
          return #err ("Actor not allowed");
        };
        let messageUpdate : Message = {
          content = c;
          vote = messageItem.vote;
          creator = messageItem.creator;
        };
        wall.put(messageId, messageUpdate);
        return #ok();
      };
    };
  };

  // Delete a specific message by ID
  public shared ({ caller }) func deleteMessage(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err ("messageId not found")};
      case(?messageItem){
        wall.delete(messageId);
        return #ok();
      };
    };
  };

  // Voting
  public func upVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err ("messageId not found")};
      case(?messageItem){
        let messageUpdate : Message = {
          content = messageItem.content;
          vote = messageItem.vote + 1;
          creator = messageItem.creator;
        };
        wall.put(messageId, messageUpdate);
        return #ok();
      };
    };
  };

  //Down Vote
  public func downVote(messageId : Nat) : async Result.Result<(), Text> {
    switch(wall.get(messageId)){
      case(null){return #err ("messageId not found")};
      case(?messageItem){
        let messageUpdate : Message = {
          content = messageItem.content;
          vote = messageItem.vote - 1;
          creator = messageItem.creator;
        };
        wall.put(messageId, messageUpdate);
        return #ok();
      };
    };
  };

  // Get all messages
  public func getAllMessages() : async [Message] {
    return Iter.toArray(wall.vals());
  };

  // Wall Order
  func compareMessages(m1 : Message, m2 : Message) : Order {
      if(m1.vote > m2.vote){
        return #greater;
      };
      if(m1.vote == m2.vote){
        return #equal;
      };
      return #less;    
  };

  // Get all messages ordered by votes
  public func getAllMessagesRanked() : async [Message] {
    let messagesOrder : [Message] = Iter.toArray(wall.vals());
    return Array.reverse(Array.sort<Message>(messagesOrder, compareMessages));
  };
};
