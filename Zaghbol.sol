pragma solidity ^0.8.0;

/**
* Teams is a contract implementation to extend upon Ownable that allows multiple controllers
* of a single contract to modify specific mint settings but not have overall ownership of the contract.
* This will easily allow cross-collaboration via Mintplex.xyz.
**/
abstract contract Teams is Ownable{
  mapping (address => bool) internal team;

  /**
  * @dev Adds an address to the team. Allows them to execute protected functions
  * @param _address the ETH address to add, cannot be 0x and cannot be in team already
  **/
  function addToTeam(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(!inTeam(_address), "This address is already in your team.");
  
    team[_address] = true;
  }

  /**
  * @dev Removes an address to the team.
  * @param _address the ETH address to remove, cannot be 0x and must be in team
  **/
  function removeFromTeam(address _address) public onlyOwner {
    require(_address != address(0), "Invalid address");
    require(inTeam(_address), "This address is not in your team currently.");
  
    team[_address] = false;
  }

  /**
  * @dev Check if an address is valid and active in the team
  * @param _address ETH address to check for truthiness
  **/
  function inTeam(address _address)
    public
    view
    returns (bool)
  {
    require(_address != address(0), "Invalid address to check.");
    return team[_address] == true;
  }

  /**
  * @dev Throws if called by any account other than the owner or team member.
  */
  modifier onlyTeamOrOwner() {
    bool _isOwner = owner() == _msgSender();
    bool _isTeam = inTeam(_msgSender());
    require(_isOwner || _isTeam, "Team: caller is not the owner or in Team.");
    _;
  }
}


  
  
/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata and Enumerable extension. Built to optimize for lower gas during batch mints.
 *
 * Assumes serials are sequentially minted starting at _startTokenId() (defaults to 0, e.g. 0, 1, 2, 3..).
 * 
 * Assumes the number of issuable tokens (collection size) is capped and fits in a uint128.
 *
 * Does not support burning tokens to address(0).
 */
contract ERC721A is
  Context,
  ERC165,
  IERC721,
  IERC721Metadata,
  IERC721Enumerable,
  Teams
{
  using Address for address;
  using Strings for uint256;

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
  }

  struct AddressData {
    uint128 balance;
    uint128 numberMinted;
  }

  uint256 private currentIndex;

  uint256 public immutable collectionSize;
  uint256 public maxBatchSize;

  // Token name
  string private _name;

  // Token symbol
  string private _symbol;

  // Mapping from token ID to ownership details
  // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
  mapping(uint256 => TokenOwnership) private _ownerships;

  // Mapping owner address to address data
  mapping(address => AddressData) private _addressData;

  // Mapping from token ID to approved address
  mapping(uint256 => address) private _tokenApprovals;

  // Mapping from owner to operator approvals
  mapping(address => mapping(address => bool)) private _operatorApprovals;

  /* @dev Mapping of restricted operator approvals set by contract Owner
  * This serves as an optional addition to ERC-721 so
  * that the contract owner can elect to prevent specific addresses/contracts
  * from being marked as the approver for a token. The reason for this
  * is that some projects may want to retain control of where their tokens can/can not be listed
  * either due to ethics, loyalty, or wanting trades to only occur on their personal marketplace.
  * By default, there are no restrictions. The contract owner must deliberatly block an address 
  */
  mapping(address => bool) public restrictedApprovalAddresses;

  /**
   * @dev
   * maxBatchSize refers to how much a minter can mint at a time.
   * collectionSize_ refers to how many tokens are in the collection.
   */
  constructor(
    string memory name_,
    string memory symbol_,
    uint256 maxBatchSize_,
    uint256 collectionSize_
  ) {
    require(
      collectionSize_ > 0,
      "ERC721A: collection must have a nonzero supply"
    );
    require(maxBatchSize_ > 0, "ERC721A: max batch size must be nonzero");
    _name = name_;
    _symbol = symbol_;
    maxBatchSize = maxBatchSize_;
    collectionSize = collectionSize_;
    currentIndex = _startTokenId();
  }

  /**
  * To change the starting tokenId, please override this function.
  */
  function _startTokenId() internal view virtual returns (uint256) {
    return 1;
  }

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  function totalSupply() public view override returns (uint256) {
    return _totalMinted();
  }

  function currentTokenId() public view returns (uint256) {
    return _totalMinted();
  }

  function getNextTokenId() public view returns (uint256) {
      return _totalMinted() + 1;
  }

  /**
  * Returns the total amount of tokens minted in the contract.
  */
  function _totalMinted() internal view returns (uint256) {
    unchecked {
      return currentIndex - _startTokenId();
    }
  }

  /**
   * @dev See {IERC721Enumerable-tokenByIndex}.
   */
  function tokenByIndex(uint256 index) public view override returns (uint256) {
    require(index < totalSupply(), "ERC721A: global index out of bounds");
    return index;
  }

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   * This read function is O(collectionSize). If calling from a separate contract, be sure to test gas first.
   * It may also degrade with extremely large collection sizes (e.g >> 10000), test for your use case.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index)
    public
    view
    override
    returns (uint256)
  {
    require(index < balanceOf(owner), "ERC721A: owner index out of bounds");
    uint256 numMintedSoFar = totalSupply();
    uint256 tokenIdsIdx = 0;
    address currOwnershipAddr = address(0);
    for (uint256 i = 0; i < numMintedSoFar; i++) {
      TokenOwnership memory ownership = _ownerships[i];
      if (ownership.addr != address(0)) {
        currOwnershipAddr = ownership.addr;
      }
      if (currOwnershipAddr == owner) {
        if (tokenIdsIdx == index) {
          return i;
        }
        tokenIdsIdx++;
      }
    }
    revert("ERC721A: unable to get token of owner by index");
  }

  /**
   * @dev See {IERC165-supportsInterface}.
   */
  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  /**
   * @dev See {IERC721-balanceOf}.
   */
  function balanceOf(address owner) public view override returns (uint256) {
    require(owner != address(0), "ERC721A: balance query for the zero address");
    return uint256(_addressData[owner].balance);
  }

  function _numberMinted(address owner) internal view returns (uint256) {
    require(
      owner != address(0),
      "ERC721A: number minted query for the zero address"
    );
    return uint256(_addressData[owner].numberMinted);
  }

  function ownershipOf(uint256 tokenId)
    internal
    view
    returns (TokenOwnership memory)
  {
    uint256 curr = tokenId;

    unchecked {
        if (_startTokenId() <= curr && curr < currentIndex) {
            TokenOwnership memory ownership = _ownerships[curr];
            if (ownership.addr != address(0)) {
                return ownership;
            }

            // Invariant:
            // There will always be an ownership that has an address and is not burned
            // before an ownership that does not have an address and is not burned.
            // Hence, curr will not underflow.
            while (true) {
                curr--;
                ownership = _ownerships[curr];
                if (ownership.addr != address(0)) {
                    return ownership;
                }
            }
        }
    }

    revert("ERC721A: unable to determine the owner of token");
  }

  /**
   * @dev See {IERC721-ownerOf}.
   */
  function ownerOf(uint256 tokenId) public view override returns (address) {
    return ownershipOf(tokenId).addr;
  }

  /**
   * @dev See {IERC721Metadata-name}.
   */
  function name() public view virtual override returns (string memory) {
    return _name;
  }

  /**
   * @dev See {IERC721Metadata-symbol}.
   */
  function symbol() public view virtual override returns (string memory) {
    return _symbol;
  }

  /**
   * @dev See {IERC721Metadata-tokenURI}.
   */
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    string memory baseURI = _baseURI();
    return
      bytes(baseURI).length > 0
        ? string(abi.encodePacked(baseURI, tokenId.toString()))
        : "";
  }

  /**
   * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
   * token will be the concatenation of the baseURI and the tokenId. Empty
   * by default, can be overriden in child contracts.
   */
  function _baseURI() internal view virtual returns (string memory) {
    return "";
  }

  /**
   * @dev Sets the value for an address to be in the restricted approval address pool.
   * Setting an address to true will disable token owners from being able to mark the address
   * for approval for trading. This would be used in theory to prevent token owners from listing
   * on specific marketplaces or protcols. Only modifible by the contract owner/team.
   * @param _address the marketplace/user to modify restriction status of
   * @param _isRestricted restriction status of the _address to be set. true => Restricted, false => Open
   */
  function setApprovalRestriction(address _address, bool _isRestricted) public onlyTeamOrOwner {
    restrictedApprovalAddresses[_address] = _isRestricted;
  }

  /**
   * @dev See {IERC721-approve}.
   */
  function approve(address to, uint256 tokenId) public override {
    address owner = ERC721A.ownerOf(tokenId);
    require(to != owner, "ERC721A: approval to current owner");
    require(restrictedApprovalAddresses[to] == false, "ERC721RestrictedApproval: Address to approve has been restricted by contract owner and is not allowed to be marked for approval");

    require(
      _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
      "ERC721A: approve caller is not owner nor approved for all"
    );

    _approve(to, tokenId, owner);
  }

  /**
   * @dev See {IERC721-getApproved}.
   */
  function getApproved(uint256 tokenId) public view override returns (address) {
    require(_exists(tokenId), "ERC721A: approved query for nonexistent token");

    return _tokenApprovals[tokenId];
  }

  /**
   * @dev See {IERC721-setApprovalForAll}.
   */
  function setApprovalForAll(address operator, bool approved) public override {
    require(operator != _msgSender(), "ERC721A: approve to caller");
    require(restrictedApprovalAddresses[operator] == false, "ERC721RestrictedApproval: Operator address has been restricted by contract owner and is not allowed to be marked for approval");

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  /**
   * @dev See {IERC721-isApprovedForAll}.
   */
  function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
  {
    return _operatorApprovals[owner][operator];
  }

  /**
   * @dev See {IERC721-transferFrom}.
   */
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    _transfer(from, to, tokenId);
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public override {
    safeTransferFrom(from, to, tokenId, "");
  }

  /**
   * @dev See {IERC721-safeTransferFrom}.
   */
  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) public override {
    _transfer(from, to, tokenId);
    require(
      _checkOnERC721Received(from, to, tokenId, _data),
      "ERC721A: transfer to non ERC721Receiver implementer"
    );
  }

  /**
   * @dev Returns whether tokenId exists.
   *
   * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
   *
   * Tokens start existing when they are minted (_mint),
   */
  function _exists(uint256 tokenId) internal view returns (bool) {
    return _startTokenId() <= tokenId && tokenId < currentIndex;
  }

  function _safeMint(address to, uint256 quantity, bool isAdminMint) internal {
    _safeMint(to, quantity, isAdminMint, "");
  }

  /**
   * @dev Mints quantity tokens and transfers them to to.
   *
   * Requirements:
   *
   * - there must be quantity tokens remaining unminted in the total collection.
   * - to cannot be the zero address.
   * - quantity cannot be larger than the max batch size.
   *
   * Emits a {Transfer} event.
   */
  function _safeMint(
    address to,
    uint256 quantity,
    bool isAdminMint,
    bytes memory _data
  ) internal {
    uint256 startTokenId = currentIndex;
    require(to != address(0), "ERC721A: mint to the zero address");
    // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
    require(!_exists(startTokenId), "ERC721A: token already minted");

    // For admin mints we do not want to enforce the maxBatchSize limit
    if (isAdminMint == false) {
        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
    }

    _beforeTokenTransfers(address(0), to, startTokenId, quantity);

    AddressData memory addressData = _addressData[to];
    _addressData[to] = AddressData(
      addressData.balance + uint128(quantity),
      addressData.numberMinted + (isAdminMint ? 0 : uint128(quantity))
    );
    _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));

    uint256 updatedIndex = startTokenId;

    for (uint256 i = 0; i < quantity; i++) {
      emit Transfer(address(0), to, updatedIndex);
      require(
        _checkOnERC721Received(address(0), to, updatedIndex, _data),
        "ERC721A: transfer to non ERC721Receiver implementer"
      );
      updatedIndex++;
    }

    currentIndex = updatedIndex;
    _afterTokenTransfers(address(0), to, startTokenId, quantity);
  }

  /**
   * @dev Transfers tokenId from from to to.
   *
   * Requirements:
   *
   * - to cannot be the zero address.
   * - tokenId token must be owned by from.
   *
   * Emits a {Transfer} event.
   */
  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) private {
    TokenOwnership memory prevOwnership = ownershipOf(tokenId);

    bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
      getApproved(tokenId) == _msgSender() ||
      isApprovedForAll(prevOwnership.addr, _msgSender()));

    require(
      isApprovedOrOwner,
      "ERC721A: transfer caller is not owner nor approved"
    );

    require(
      prevOwnership.addr == from,
      "ERC721A: transfer from incorrect owner"
    );
    require(to != address(0), "ERC721A: transfer to the zero address");

    _beforeTokenTransfers(from, to, tokenId, 1);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId, prevOwnership.addr);

    _addressData[from].balance -= 1;
    _addressData[to].balance += 1;
    _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));

    // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
    // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
    uint256 nextTokenId = tokenId + 1;
    if (_ownerships[nextTokenId].addr == address(0)) {
      if (_exists(nextTokenId)) {
        _ownerships[nextTokenId] = TokenOwnership(
          prevOwnership.addr,
          prevOwnership.startTimestamp
        );
      }
    }

    emit Transfer(from, to, tokenId);
    _afterTokenTransfers(from, to, tokenId, 1);
  }

  /**
   * @dev Approve to to operate on tokenId
   *
   * Emits a {Approval} event.
   */
  function _approve(
    address to,
    uint256 tokenId,
    address owner
  ) private {
    _tokenApprovals[tokenId] = to;
    emit Approval(owner, to, tokenId);
  }

  uint256 public nextOwnerToExplicitlySet = 0;

  /**
   * @dev Explicitly set owners to eliminate loops in future calls of ownerOf().
   */
  function _setOwnersExplicit(uint256 quantity) internal {
    uint256 oldNextOwnerToSet = nextOwnerToExplicitlySet;
    require(quantity > 0, "quantity must be nonzero");
    if (currentIndex == _startTokenId()) revert('No Tokens Minted Yet');

    uint256 endIndex = oldNextOwnerToSet + quantity - 1;
    if (endIndex > collectionSize - 1) {
      endIndex = collectionSize - 1;
    }
    // We know if the last one in the group exists, all in the group exist, due to serial ordering.
    require(_exists(endIndex), "not enough minted yet for this cleanup");
    for (uint256 i = oldNextOwnerToSet; i <= endIndex; i++) {
      if (_ownerships[i].addr == address(0)) {
        TokenOwnership memory ownership = ownershipOf(i);
        _ownerships[i] = TokenOwnership(
          ownership.addr,
          ownership.startTimestamp
        );
      }
    }
    nextOwnerToExplicitlySet = endIndex + 1;
  }

  /**
   * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
   * The call is not executed if the target address is not a contract.
   *
   * @param from address representing the previous owner of the given token ID
   * @param to target address that will receive the tokens
   * @param tokenId uint256 ID of the token to be transferred
   * @param _data bytes optional data to send along with the call
   * @return bool whether the call correctly returned the expected magic value
   */
  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver(to).onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721A: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    } else {
      return true;
    }
  }

  /**
   * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - When from and to are both non-zero, from's tokenId will be
   * transferred to to.
   * - When from is zero, tokenId will be minted for to.
   */
  function _beforeTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}

  /**
   * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
   * minting.
   *
   * startTokenId - the first token id to be transferred
   * quantity - the amount to be transferred
   *
   * Calling conditions:
   *
   * - when from and to are both non-zero.
   * - from and to are never both zero.
   */
  function _afterTokenTransfers(
    address from,
    address to,
    uint256 startTokenId,
    uint256 quantity
  ) internal virtual {}
}



  
abstract contract Ramppable {
  address public RAMPPADDRESS = 0xa9dAC8f3aEDC55D0FE707B86B8A45d246858d2E1;

  modifier isRampp() {
      require(msg.sender == RAMPPADDRESS, "Ownable: caller is not RAMPP");
      _;
  }
}


  
  
interface IERC20 {
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address _to, uint256 _amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// File: WithdrawableV2
// This abstract allows the contract to be able to mint and ingest ERC-20 payments for mints.
// ERC-20 Payouts are limited to a single payout address. This feature 
// will charge a small flat fee in native currency that is not subject to regular rev sharing.
// This contract also covers the normal functionality of accepting native base currency rev-sharing
abstract contract WithdrawableV2 is Teams, Ramppable {
  struct acceptedERC20 {
    bool isActive;
    uint256 chargeAmount;
  }

  
  mapping(address => acceptedERC20) private allowedTokenContracts;
  address[] public payableAddresses = [RAMPPADDRESS,0x7a98Af980f1e3627aDA220C09F7661Ed96CA96DF];
  address[] public surchargePayableAddresses = [RAMPPADDRESS];
  address public erc20Payable = 0x7a98Af980f1e3627aDA220C09F7661Ed96CA96DF;
  uint256[] public payableFees = [5,95];
  uint256[] public surchargePayableFees = [100];
  uint256 public payableAddressCount = 2;
  uint256 public surchargePayableAddressCount = 1;
  uint256 public ramppSurchargeBalance = 0 ether;
  uint256 public ramppSurchargeFee = 0.001 ether;
  bool public onlyERC20MintingMode = false;
  

  /**
  * @dev Calculates the true payable balance of the contract as the
  * value on contract may be from ERC-20 mint surcharges and not 
  * public mint charges - which are not eligable for rev share & user withdrawl
  */
  function calcAvailableBalance() public view returns(uint256) {
    return address(this).balance - ramppSurchargeBalance;
  }

  function withdrawAll() public onlyTeamOrOwner {
      require(calcAvailableBalance() > 0);
      _withdrawAll();
  }
  
  function withdrawAllRampp() public isRampp {
      require(calcAvailableBalance() > 0);
      _withdrawAll();
  }

  function _withdrawAll() private {
      uint256 balance = calcAvailableBalance();
      
      for(uint i=0; i < payableAddressCount; i++ ) {
          _widthdraw(
              payableAddresses[i],
              (balance * payableFees[i]) / 100
          );
      }
  }
  
  function _widthdraw(address _address, uint256 _amount) private {
      (bool success, ) = _address.call{value: _amount}("");
      require(success, "Transfer failed.");
  }

  /**
  * @dev This function is similiar to the regular withdraw but operates only on the
  * balance that is available to surcharge payout addresses. This would be Rampp + partners
  **/
  function _withdrawAllSurcharges() private {
    uint256 balance = ramppSurchargeBalance;
    if(balance == 0) { return; }
    
    for(uint i=0; i < surchargePayableAddressCount; i++ ) {
        _widthdraw(
            surchargePayableAddresses[i],
            (balance * surchargePayableFees[i]) / 100
        );
    }
    ramppSurchargeBalance = 0 ether;
  }

  /**
  * @dev Allow contract owner to withdraw ERC-20 balance from contract
  * in the event ERC-20 tokens are paid to the contract for mints. This will
  * send the tokens to the payout as well as payout the surcharge fee to Rampp
  * @param _tokenContract contract of ERC-20 token to withdraw
  * @param _amountToWithdraw balance to withdraw according to balanceOf of ERC-20 token in wei
  */
  function withdrawERC20(address _tokenContract, uint256 _amountToWithdraw) public onlyTeamOrOwner {
    require(_amountToWithdraw > 0);
    IERC20 tokenContract = IERC20(_tokenContract);
    require(tokenContract.balanceOf(address(this)) >= _amountToWithdraw, "WithdrawV2: Contract does not own enough tokens");
    tokenContract.transfer(erc20Payable, _amountToWithdraw); // Payout ERC-20 tokens to recipient
    _withdrawAllSurcharges();
  }

  /**
  * @dev Allow Rampp to be able to withdraw only its ERC-20 payment surcharges from the contract.
  */
  function withdrawRamppSurcharges() public isRampp {
    require(ramppSurchargeBalance > 0, "WithdrawableV2: No Rampp surcharges in balance.");
    _withdrawAllSurcharges();
  }

   /**
  * @dev Helper function to increment Rampp surcharge balance when ERC-20 payment is made.
  */
  function addSurcharge() internal {
    ramppSurchargeBalance += ramppSurchargeFee;
  }
  
  /**
  * @dev Helper function to enforce Rampp surcharge fee when ERC-20 mint is made.
  */
  function hasSurcharge() internal returns(bool) {
    return msg.value == ramppSurchargeFee;
  }

  /**
  * @dev Set surcharge fee for using ERC-20 payments on contract
  * @param _newSurcharge is the new surcharge value of native currency in wei to facilitate ERC-20 payments
  */
  function setRamppSurcharge(uint256 _newSurcharge) public isRampp {
    ramppSurchargeFee = _newSurcharge;
  }

  /**
  * @dev check if an ERC-20 contract is a valid payable contract for executing a mint.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function isApprovedForERC20Payments(address _erc20TokenContract) public view returns(bool) {
    return allowedTokenContracts[_erc20TokenContract].isActive == true;
  }

  /**
  * @dev get the value of tokens to transfer for user of an ERC-20
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function chargeAmountForERC20(address _erc20TokenContract) public view returns(uint256) {
    require(isApprovedForERC20Payments(_erc20TokenContract), "This ERC-20 contract is not approved to make payments on this contract!");
    return allowedTokenContracts[_erc20TokenContract].chargeAmount;
  }

  /**
  * @dev Explicity sets and ERC-20 contract as an allowed payment method for minting
  * @param _erc20TokenContract address of ERC-20 contract in question
  * @param _isActive default status of if contract should be allowed to accept payments
  * @param _chargeAmountInTokens fee (in tokens) to charge for mints for this specific ERC-20 token
  */
  function addOrUpdateERC20ContractAsPayment(address _erc20TokenContract, bool _isActive, uint256 _chargeAmountInTokens) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = _isActive;
    allowedTokenContracts[_erc20TokenContract].chargeAmount = _chargeAmountInTokens;
  }

  /**
  * @dev Add an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function enableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = true;
  }

  /**
  * @dev Disable an ERC-20 contract as being a valid payment method. If passed a contract which has not been added
  * it will assume the default value of zero. This should not be used to create new payment tokens.
  * @param _erc20TokenContract address of ERC-20 contract in question
  */
  function disableERC20ContractAsPayment(address _erc20TokenContract) public onlyTeamOrOwner {
    allowedTokenContracts[_erc20TokenContract].isActive = false;
  }

  /**
  * @dev Enable only ERC-20 payments for minting on this contract
  */
  function enableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = true;
  }

  /**
  * @dev Disable only ERC-20 payments for minting on this contract
  */
  function disableERC20OnlyMinting() public onlyTeamOrOwner {
    onlyERC20MintingMode = false;
  }

  /**
  * @dev Set the payout of the ERC-20 token payout to a specific address
  * @param _newErc20Payable new payout addresses of ERC-20 tokens
  */
  function setERC20PayableAddress(address _newErc20Payable) public onlyTeamOrOwner {
    require(_newErc20Payable != address(0), "WithdrawableV2: new ERC-20 payout cannot be the zero address");
    require(_newErc20Payable != erc20Payable, "WithdrawableV2: new ERC-20 payout is same as current payout");
    erc20Payable = _newErc20Payable;
  }

  /**
  * @dev Reset the Rampp surcharge total to zero regardless of value on contract currently.
  */
  function resetRamppSurchargeBalance() public isRampp {
    ramppSurchargeBalance = 0 ether;
  }

  /**
  * @dev Allows Rampp wallet to update its own reference as well as update
  * the address for the Rampp-owed payment split. Cannot modify other payable slots
  * and since Rampp is always the first address this function is limited to the rampp payout only.
  * @param _newAddress updated Rampp Address
  */
  function setRamppAddress(address _newAddress) public isRampp {
    require(_newAddress != RAMPPADDRESS, "WithdrawableV2: New Rampp address must be different");
    RAMPPADDRESS = _newAddress;
    payableAddresses[0] = _newAddress;
  }
}


  
// File: isFeeable.sol
abstract contract Feeable is Teams {
  uint256 public PRICE = 0.01 ether;

  function setPrice(uint256 _feeInWei) public onlyTeamOrOwner {
    PRICE = _feeInWei;
  }

  function getPrice(uint256 _count) public view returns (uint256) {
    return PRICE * _count;
  }
}

  
  
  
abstract contract RamppERC721A is 
    Ownable,
    Teams,
    ERC721A,
    WithdrawableV2,
    ReentrancyGuard 
    , Feeable 
     
    
{
  constructor(
    string memory tokenName,
    string memory tokenSymbol
  ) ERC721A(tokenName, tokenSymbol, 2, 5000) { }
    uint8 public CONTRACT_VERSION = 2;
    string public _baseTokenURI = "ipfs://bafybeifi6ybvjdixymttzulpdhzbdllnpel7jnpp2qoq43pwdfhaqodwhm/";

    bool public mintingOpen = true;
    
    

  
    /////////////// Admin Mint Functions
    /**
     * @dev Mints a token to an address with a tokenURI.
     * This is owner only and allows a fee-free drop
     * @param _to address of the future owner of the token
     * @param _qty amount of tokens to drop the owner
     */
     function mintToAdminV2(address _to, uint256 _qty) public onlyTeamOrOwner{
         require(_qty > 0, "Must mint at least 1 token.");
         require(currentTokenId() + _qty <= collectionSize, "Cannot mint over supply cap of 5000");
         _safeMint(_to, _qty, true);
     }

  
    /////////////// GENERIC MINT FUNCTIONS
    /**
    * @dev Mints a single token to an address.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    */
    function mintTo(address _to) public payable {
        require(onlyERC20MintingMode == false, "Only minting with ERC-20 tokens is enabled.");
        require(getNextTokenId() <= collectionSize, "Cannot mint over supply cap of 5000");
        require(mintingOpen == true, "Minting is not open right now!");
        
        
        require(msg.value == getPrice(1), "Value needs to be exactly the mint fee!");
        
        _safeMint(_to, 1, false);
    }

    /**
    * @dev Mints tokens to an address in batch.
    * fee may or may not be required*
    * @param _to address of the future owner of the token
    * @param _amount number of tokens to mint
    */
    function mintToMultiple(address _to, uint256 _amount) public payable {
        require(onlyERC20MintingMode == false, "Only minting with ERC-20 tokens is enabled.");
        require(_amount >= 1, "Must mint at least 1 token");
        require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
        require(mintingOpen == true, "Minting is not open right now!");
        
        
        require(currentTokenId() + _amount <= collectionSize, "Cannot mint over supply cap of 5000");
        require(msg.value == getPrice(_amount), "Value below required mint fee for amount");

        _safeMint(_to, _amount, false);
    }

    /**
     * @dev Mints tokens to an address in batch using an ERC-20 token for payment
     * fee may or may not be required*
     * @param _to address of the future owner of the token
     * @param _amount number of tokens to mint
     * @param _erc20TokenContract erc-20 token contract to mint with
     */
    function mintToMultipleERC20(address _to, uint256 _amount, address _erc20TokenContract) public payable {
      require(_amount >= 1, "Must mint at least 1 token");
      require(_amount <= maxBatchSize, "Cannot mint more than max mint per transaction");
      require(getNextTokenId() <= collectionSize, "Cannot mint over supply cap of 5000");
      require(mintingOpen == true, "Minting is not open right now!");
      
      

      // ERC-20 Specific pre-flight checks
      require(isApprovedForERC20Payments(_erc20TokenContract), "ERC-20 Token is not approved for minting!");
      uint256 tokensQtyToTransfer = chargeAmountForERC20(_erc20TokenContract) * _amount;
      IERC20 payableToken = IERC20(_erc20TokenContract);

      require(payableToken.balanceOf(_to) >= tokensQtyToTransfer, "Buyer does not own enough of token to complete purchase");
      require(payableToken.allowance(_to, address(this)) >= tokensQtyToTransfer, "Buyer did not approve enough of ERC-20 token to complete purchase");
      require(hasSurcharge(), "Fee for ERC-20 payment not provided!");
      
      bool transferComplete = payableToken.transferFrom(_to, address(this), tokensQtyToTransfer);
      require(transferComplete, "ERC-20 token was unable to be transferred");
      
      _safeMint(_to, _amount, false);
      addSurcharge();
    }

    function openMinting() public onlyTeamOrOwner {
        mintingOpen = true;
    }

    function stopMinting() public onlyTeamOrOwner {
        mintingOpen = false;
    }

  

  

  
    /**
     * @dev Allows owner to set Max mints per tx
     * @param _newMaxMint maximum amount of tokens allowed to mint per tx. Must be >= 1
     */
     function setMaxMint(uint256 _newMaxMint) public onlyTeamOrOwner {
         require(_newMaxMint >= 1, "Max mint must be at least 1");
         maxBatchSize = _newMaxMint;
     }
    

  

  function _baseURI() internal view virtual override returns(string memory) {
    return _baseTokenURI;
  }

  function baseTokenURI() public view returns(string memory) {
    return _baseTokenURI;
  }

  function setBaseURI(string calldata baseURI) external onlyTeamOrOwner {
    _baseTokenURI = baseURI;
  }

  function getOwnershipData(uint256 tokenId) external view returns(TokenOwnership memory) {
    return ownershipOf(tokenId);
  }
}


  
