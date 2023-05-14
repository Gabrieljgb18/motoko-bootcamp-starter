import Buffer "mo:base/Buffer";
import Result "mo:base/Result";
import Array "mo:base/Array";
import Time "mo:base/Time";

import Type "Types";

actor class Homework() {
  type Homework = Type.Homework;
  let homework : Buffer.Buffer<Homework> = Buffer.Buffer<Homework>(0);
  // Add a new homework task
  public shared func addHomework(homeworkItem : Homework) : async Nat {
    homework.add(homeworkItem);
    var homeworkId = homework.size();
    return homeworkId - 1;
  };

  // Get a specific homework task by id
  public shared query func getHomework(homeworkId : Nat) : async Result.Result<Homework, Text> {
    if (homeworkId < homework.size()) {
      return #ok(homework.get(homeworkId));
    };
    return #err("homeworkId not found");
  };

  // Update a homework task's title, description, and/or due date
  public shared func updateHomework(homeworkId : Nat, homeworkItem : Homework) : async Result.Result<(), Text> {
    if (homeworkId < homework.size()) {
      homework.put(homeworkId, homeworkItem);
      return #ok();
    };
    return #err("homeworkId not found");

  };

  // Mark a homework task as completed
  public shared func markAsCompleted(homeworkId : Nat) : async Result.Result<(), Text> {
    if (homeworkId >= homework.size()) {
      return #err("homeworkId not found");
    };
    let homeworkItem : Homework = homework.get(homeworkId);
    let homeworkUpgrade : Homework = {
      title = homeworkItem.title;
      description = homeworkItem.description;
      dueDate = homeworkItem.dueDate;
      completed = true;
    };
    homework.put(homeworkId, homeworkUpgrade);
    return #ok();

  };

  // Delete a homework task by id
  public shared func deleteHomework(homeworkId : Nat) : async Result.Result<(), Text> {
    if (homeworkId < homework.size()) {
      ignore homework.remove(homeworkId);
      return #ok();
    };
    return #err("homeworkId not found");
  };

  // Get the list of all homework tasks
  public shared query func getAllHomework() : async [Homework] {
    return Buffer.toArray(homework);
  };

  // Get the list of pending (not completed) homework tasks
  public shared query func getPendingHomework() : async [Homework] {
    var pending : Buffer.Buffer<Homework> = Buffer.Buffer(0);
    for (i in homework.vals()) {
      if (not i.completed) {
        pending.add(i);
      };
    };
    return Buffer.toArray(pending);
  };

  // Search for homework tasks based on a search terms
  public shared query func searchHomework(searchTerm : Text) : async [Homework] {
    var homeworkFound : Buffer.Buffer<Homework> = Buffer.Buffer(0);
    for (i in homework.vals()) {
      if (i.title == searchTerm or i.description == searchTerm) {
        homeworkFound.add(i);
      };
    };
    return Buffer.toArray(homeworkFound);
  };
};
