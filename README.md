## Foundry

an ERC721 marketplace that uses onchain orders coupled with vrs signatures to create and confirm orders

### the marketplace allow users to create erc721 orders for their erc721 tokens
### the order should have the following info 
  
### order creator/token owner(obviously)
  
### erc721 token address, tokenID
  
### price(we'll be using only ether as currency) - active
  
### signature(the seller must sign the previous data i.e the hash of the token address,tokenId,price,owner etc)
  
### deadline, if the token isn't sold before the deadline, it cannot be bought again

### when the order is being created by the buyer, the signature is being verified to be the owner's  address among other checks

### order fulfillment has its own checks too


# Blue print link -> https://docs.google.com/document/d/1DyOgz7VGDE1STwLX12LHalbo11Nh1Lu02VrwqOmxjn4/edit?usp=sharing
