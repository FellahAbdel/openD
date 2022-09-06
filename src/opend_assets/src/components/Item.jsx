import React, { useEffect, useState } from "react";
import logo from "../../assets/logo.png";
import { Actor, HttpAgent } from "@dfinity/agent";
import { idlFactory } from "../../../declarations/nft";
import { Principal } from "@dfinity/principal";
import Button from "./Button";
import { opend } from "../../../declarations/opend/index";

function Item(props) {
  const id = props.id;
  const [name, setName] = useState();
  const [owner, setOwner] = useState();
  const [image, setImage] = useState();
  const [textInput, setTextInput] = useState();
  const [loaderHidden, setLoaderHidden] = useState(true);
  const [blur, setBlur] = useState();
  const [button, setButton] = useState();
  const [sellStatus, setSellStatus] = useState("");

  const localHost = "http://localhost:8080/";
  let NFTActor;
  const agent = new HttpAgent({
    host: localHost,
  });
  agent.fetchRootKey();

  async function loadNFT() {
    NFTActor = await Actor.createActor(idlFactory, {
      agent,
      canisterId: id,
    });

    const name = await NFTActor.getName();
    setName(name);
    const owner = await NFTActor.getOwner();
    setOwner(owner.toString());
    const imageContent = await NFTActor.getAsset();
    const imageData = new Uint8Array(imageContent);
    const blob = new Blob([imageData.buffer], { type: "image/png" });
    const image = URL.createObjectURL(blob);
    setImage(image);

    const nftIsListed = await opend.isListed(props.id);
    if (nftIsListed) {
      setOwner("OpenD");
      setBlur({ filter: "blur(4px)" });
    } else {
      setButton(<Button handleClick={handleSell} text={"Sell"} />);
    }
  }

  let price;
  function handleSell() {
    setTextInput(
      <input
        placeholder="Price in DANG"
        type="number"
        className="price-input"
        value={price}
        onChange={(e) => (price = e.target.value)}
      />
    );
    setButton(<Button handleClick={sellNFT} text={"Confirm"} />);
  }

  async function sellNFT() {
    setLoaderHidden(false);
    setBlur({ filter: "blur(4px)" });
    console.log(price);
    const listingResult = await opend.listItem(props.id, Number(price));
    console.log("listing: " + listingResult);
    if (listingResult === "Success") {
      const opendCanisterId = await opend.getOpendCanisterId();
      const transferResult = await NFTActor.transferOwnership(opendCanisterId);
      console.log(transferResult);
      if (transferResult === "Success") {
        setLoaderHidden(true);
        setOwner("OpenD");
        setTextInput();
        setButton();
        setSellStatus("Listed");
      }
    }
  }

  useEffect(() => {
    loadNFT();
  }, []);

  return (
    <div className="disGrid-item">
      <div className="disPaper-root disCard-root makeStyles-root-17 disPaper-elevation1 disPaper-rounded">
        <img
          className="disCardMedia-root makeStyles-image-19 disCardMedia-media disCardMedia-img"
          src={image}
          style={blur}
        />
        <div className="lds-ellipsis" hidden={loaderHidden}>
          <div></div>
          <div></div>
          <div></div>
          <div></div>
        </div>
        <div className="disCardContent-root">
          <h2 className="disTypography-root makeStyles-bodyText-24 disTypography-h5 disTypography-gutterBottom">
            {name}
            <span className="purple-text"> {sellStatus}</span>
          </h2>
          <p className="disTypography-root makeStyles-bodyText-24 disTypography-body2 disTypography-colorTextSecondary">
            Owner: {owner}
          </p>
          {textInput}
          {button}
        </div>
      </div>
    </div>
  );
}

export default Item;
