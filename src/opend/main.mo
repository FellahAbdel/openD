import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import NFTActorClass "../NFT/nft";
import NFTs "mo:base/Trie";
import Principal "mo:base/Principal";
import List "mo:base/List";

actor OpenD {
    private type Listing = {
        itemOwner : Principal;
        itemPrice : Nat;
    };

    let mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    let mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);
    let mapOfListings = HashMap.HashMap<Principal, Listing>(1, Principal.equal, Principal.hash);

    public shared(msg) func mint(imageData: [Nat8], name : Text) : async Principal{
        let owner : Principal = msg.caller;
        Debug.print(debug_show(Cycles.balance()));

        Cycles.add(100_500_000_000);
        Debug.print(debug_show(Cycles.balance()));
        let newNFT = await NFTActorClass.NFT(name,owner,imageData);
        let newNFTPrincipal = await newNFT.getCanisterId();

        mapOfNFTs.put(newNFTPrincipal, newNFT);
        addToOwnershipMap(owner, newNFTPrincipal);
        return newNFTPrincipal;
    };
    
    private func addToOwnershipMap(owner : Principal, nftId : Principal) {
        //We try to see if the owner has already an NFT, if not we create nil List,
        //else we get back a List of his NFTs
        var ownedNFTs : List.List<Principal> = switch(mapOfOwners.get(owner)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        // Then we add the new NFT to his ownedNFTs
        ownedNFTs := List.push(nftId, ownedNFTs);
        mapOfOwners.put(owner, ownedNFTs);
    };

    public query func getOwnedNfts(user: Principal) : async [Principal] {
        var userNFTs : List.List<Principal> = switch(mapOfOwners.get(user)){
            case null List.nil<Principal>();
            case (?result) result;
        };

        return List.toArray(userNFTs);
    };

    public shared(msg) func listItem(id: Principal, price : Nat) : async Text {
        var item : NFTActorClass.NFT = switch(mapOfNFTs.get(id)) {
            case null return "NFT does not exists";
            case (?result) result;
        };

        let owner = await item.getOwner();

        if(Principal.equal(owner, msg.caller)) {
            // The item belong to the user
            let newListing : Listing = {
                itemOwner = owner;
                itemPrice = price;
            };

            mapOfListings.put(id, newListing);
            return "Success";
        }else {
            return "You don't own the NFT";
        }
    };

    public query func getOpendCanisterId() : async Principal {
        return Principal.fromActor(OpenD);
    };

    // Check if the NFT is listed for sale
    public query func isListed(id: Principal) : async Bool {
        if(mapOfListings.get(id) == null){
            return false;
        }else {
            return true;
        }
    }
};
