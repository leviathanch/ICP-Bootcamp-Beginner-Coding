import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Nat32 "mo:base/Nat32";
import Int "mo:base/Int";
import Iter "mo:base/Iter";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";
import List "mo:base/List";

import Debug "mo:base/Debug";

import { get_new_memory_storage; MemoryHashTable; Blobify } "mo:memory-hashtable";

actor {
    stable var autoIndex = 0;
    stable var mem = get_new_memory_storage(8);
    var userIdTable = MemoryHashTable(mem);
    var userNameTable = MemoryHashTable(mem);
    var userDataTable = MemoryHashTable(mem);

    // Read and write user data
    private func getUserData(userIdBlob : Blob) : [Text] {
        return switch(userDataTable.get(userIdBlob)) {
            case(null){
                return [""];
            };
            case(? userDataBlob) {
                let userDataString = Blobify.Text.from_blob(userDataBlob);
                let userDataIter = Text.split(userDataString, #char ',');
                let userData:[Text] = Iter.toArray(userDataIter);
                return userData;
            };
        };
    };

    // Helper function for making my life easier
    private func blobToUserName(userIdBlob : Blob) : Text {
        return switch(userNameTable.get(userIdBlob)) {
            case(null){
                return "";
            };
            case(? userNameBlob){
                return Blobify.Text.from_blob(userNameBlob);
            };
        };
    };

    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let key = Blobify.Principal.to_blob(caller);
        switch(userIdTable.get(key)) {
            case(null){
                return #err("User unknown");
            };
            case(? userIdBlob){
                let userId:Nat = Blobify.Nat.from_blob(userIdBlob);
                let userName:Text = blobToUserName(userIdBlob);
                return #ok({ id = userId; name = userName });
            };
        };
    };

    public shared ({ caller }) func setUserProfile(name : Text) : async Result.Result<{ id : Nat; name : Text }, Text> {
        let key = Blobify.Principal.to_blob(caller);
        let userNameBlob:Blob = Blobify.Text.to_blob(name);
        switch(userIdTable.get(key)) {
            case(null){
                autoIndex += 1;
                let userIdBlob:Blob = Blobify.Nat.to_blob(autoIndex);
                ignore userIdTable.put(key, userIdBlob);
                ignore userNameTable.put(userIdBlob, userNameBlob);
                return #ok({ id = autoIndex; name = name });
            };
            case(? userIdBlob){
                let userId = Blobify.Nat.from_blob(userIdBlob);
                ignore userNameTable.put(userIdBlob, userNameBlob);
                return #ok({ id = userId; name = name });
            };
        };
    };

    public shared ({ caller }) func addUserResult(result : Text) : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        Debug.print("addUserResult");
        let key = Blobify.Principal.to_blob(caller);
        switch(userIdTable.get(key)) {
            case(null){
                return #err("User unknown");
            };
            case(? userIdBlob){
                let userId:Nat = Blobify.Nat.from_blob(userIdBlob);
                let userResults : [Text] = getUserData(userIdBlob); 
                let newUserResults = Array.append<Text>(userResults, [result]);
                let newUserResultsString = Text.join(",", newUserResults.vals());
                let newUserResultsBlob = Blobify.Text.to_blob(newUserResultsString);
                ignore userDataTable.put(userIdBlob,newUserResultsBlob);
                return #ok({ id = userId; results = newUserResults });
            };
        };
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        Debug.print("getUserResults");
        let key = Blobify.Principal.to_blob(caller);
        switch(userIdTable.get(key)) {
            case(null){
                return #err("User unknown");
            };
            case(? userIdBlob){
                let userId:Nat = Blobify.Nat.from_blob(userIdBlob);
                let userResults : [Text] = getUserData(userIdBlob); 
                return #ok({ id = userId; results = userResults });
            };
        };
    };
};
