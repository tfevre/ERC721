// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./IExerciceSolution.sol";

contract BoredAlpacas is ERC721, IExerciceSolution {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    struct Animal { 
        uint sex;
        uint legs;
        bool wings;
        string name;
        bool alive;
        bool forSale;
        uint256 price;
        uint256 parent1;
        uint256 parent2;
        bool canReproduce;
        uint reproductionPrice;
    }
    uint256[] public idList;
    mapping(uint => Animal) public animalList;
    mapping(address => bool) public breederList;
    mapping(uint256 => address) public reproductionBreederList;

    constructor() ERC721("BoredAlpacas", "BA") {
        _tokenIdCounter.increment();
    }

    function Mint(address _to, uint _id) public {
        _mint(_to, _id);
        idList.push(_id);
        _tokenIdCounter.increment();     
    }

    function isBreeder(address account) external override returns (bool){
        if (breederList[account]){
            return true;
        }
        return false;
    }

	function registrationPrice() external override returns (uint256){
        return 1;
    }

	function registerMeAsBreeder() external override payable{
        breederList[msg.sender] = true;
    }

	function declareAnimal(uint sex, uint legs, bool wings, string calldata name) external override returns (uint256){
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current(); 
        animalList[tokenId] = Animal(sex, legs, wings, name, true, false, 0, 0, 0, false, 0);
        idList.push(tokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

	function getAnimalCharacteristics(uint animalNumber) external override returns (string memory _name, bool _wings, uint _legs, uint _sex){
        Animal memory data = animalList[animalNumber];
        if (data.alive){
            return (data.name, data.wings, data.legs, data.sex);
        }
        return ("", false, 0, 0);
    }

	function declareDeadAnimal(uint animalNumber) external override {
        require(ownerOf(animalNumber) == msg.sender, "BoredAlpacas: this is not your animal");
        animalList[animalNumber].alive = false;
        uint256[] memory tmpIdList = idList;
        idList = new uint256[](0);
        for (uint i = 0; i < tmpIdList.length; i++){
            if (tmpIdList[i]!=animalNumber){
                idList.push(tmpIdList[i]);
            }
        }
        _burn(animalNumber);
    }

	function tokenOfOwnerByIndex(address owner, uint256 index) external override view returns (uint256){
        uint tmpIndex;
        for (uint i = 0; i < idList.length; i++){
            if (this.ownerOf(idList[i]) == owner){
                return idList[i];
            }
        }
        return 0;
    }

	// Selling functions
	function isAnimalForSale(uint animalNumber) external override view returns (bool){
        if (animalList[animalNumber].forSale){
            return true;
        }
        return false;
    }

	function animalPrice(uint animalNumber) external override view returns (uint256){
        if (animalList[animalNumber].forSale){
            return animalList[animalNumber].price;
        }
        return 0;
    }

	function buyAnimal(uint animalNumber) override external payable{
        require(animalList[animalNumber].forSale, "BoredAlpacas: animal not for sale");
        require(msg.value >= animalList[animalNumber].price, "BoredAlpacas: price incorrect");
        transferFrom(ownerOf(animalNumber), msg.sender, animalNumber);
    }

	function offerForSale(uint animalNumber, uint price) override external{
        if (ownerOf(animalNumber) == msg.sender){
            animalList[animalNumber].forSale = true;
            animalList[animalNumber].price = price;
            approve(address(this), animalNumber);
        }
    }

	// Reproduction functions

	function declareAnimalWithParents(uint sex, uint legs, bool wings, string calldata name, uint parent1, uint parent2) external override returns (uint256){
        if (ownerOf(parent1) != msg.sender){
            require(animalList[parent1].canReproduce, "BoredAlpacas: parent 1 cannot reproduce");
            require(reproductionBreederList[parent1] == msg.sender, "BoredAlpacas: you are not allowed to reproduce with p1");
            reproductionBreederList[parent1] = address(0);
        } 
        if (ownerOf(parent2) != msg.sender){
            require(animalList[parent2].canReproduce, "BoredAlpacas: parent 2 cannot reproduce");
            require(reproductionBreederList[parent2] == msg.sender, "BoredAlpacas: you are not allowed to reproduce with p2");
            reproductionBreederList[parent2] = address(0);
        } 
        _tokenIdCounter.increment();
        uint256 tokenId = _tokenIdCounter.current(); 
        animalList[tokenId] = Animal(sex, legs, wings, name, true, false, 0, parent1, parent2, false, 0);
        idList.push(tokenId);
        _mint(msg.sender, tokenId);
        return tokenId;
    }

	function getParents(uint animalNumber) external override returns (uint256, uint256){
        if (animalList[animalNumber].alive){
            return (animalList[animalNumber].parent1, animalList[animalNumber].parent2);
        }
        return (0, 0);
    }

	function canReproduce(uint animalNumber) external override returns (bool){
        return animalList[animalNumber].canReproduce;
    }

	function reproductionPrice(uint animalNumber) external override view returns (uint256){
        return animalList[animalNumber].reproductionPrice;
    }

	function offerForReproduction(uint animalNumber, uint priceOfReproduction) external override returns (uint256){
        require(ownerOf(animalNumber)==msg.sender, "BoredAlpacas: you are not the owner");
        animalList[animalNumber].canReproduce = true;
        animalList[animalNumber].reproductionPrice = priceOfReproduction;
    }

	function authorizedBreederToReproduce(uint animalNumber) external override returns (address) {
        return reproductionBreederList[animalNumber];
    }

	function payForReproduction(uint animalNumber) external override payable{
        require(msg.value >= animalList[animalNumber].reproductionPrice, "BoredAlpacas: not enough ETH send, price is higher");
        reproductionBreederList[animalNumber] = msg.sender;
    }


}
