import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import HashMap "mo:base/HashMap";
import NFTActorClass "../NFT/nft";
import NFTs "mo:base/Trie";
import Principal "mo:base/Principal";
import List "mo:base/List";

actor OpenD {
    let mapOfNFTs = HashMap.HashMap<Principal, NFTActorClass.NFT>(1, Principal.equal, Principal.hash);
    let mapOfOwners = HashMap.HashMap<Principal, List.List<Principal>>(1, Principal.equal, Principal.hash);

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
    }
};
