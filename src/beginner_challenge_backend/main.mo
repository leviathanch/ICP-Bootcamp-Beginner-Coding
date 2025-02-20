import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Principal "mo:base/Principal";

import Debug "mo:base/Debug";

import Blobify "mo:memory-buffer/Blobify";
import { get_new_memory_storage; MemoryHashTable } "mo:memory-hashtable";

actor {
    stable var autoIndex = 0;
    stable var mem = get_new_memory_storage(8);
    var userIdTable = MemoryHashTable(mem);
    var userNameTable = MemoryHashTable(mem);

    private func blobToUserName(userIdBlob : Blob) : Text {
        switch(userNameTable.get(userIdBlob)) {
            case(null){
                return "";
            };
            case(? userNameBlob){
                return Blobify.Text.from_blob(userNameBlob);
            };
        };
        return "";
    };

    public query ({ caller }) func getUserProfile() : async Result.Result<{ id : Nat; name : Text }, Text> {
        let key = Blobify.Principal.to_blob(caller);
        var userName:Text = "";
        var getUserName = false;
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
        return #ok({ id = 123; results = ["fake result"] });
    };

    public query ({ caller }) func getUserResults() : async Result.Result<{ id : Nat; results : [Text] }, Text> {
        Debug.print("getUserResults");
        return #ok({ id = 123; results = ["fake result"] });
    };
};
