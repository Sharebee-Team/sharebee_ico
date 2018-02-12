pragma solidity ^0.4.4;


/*
Review Ideas:
flaggable?
removable -- only if flagged? 




*/
contract Review{
  mapping(address => bool) owners;
  mapping(address => mapping(address => uint256)) public reviewIndexes;
  mapping(address=> ReviewData[]) public reviews;

  struct ReviewData {
    address reviewer;
    string comment;
    uint256 rating; //rating will scale by 1/2. ex. 3 is a rating of 1.5, 8 is a rating of 4
  }




  function submitReview(address _to, string _review, uint256 _rating){
    if(!reviewIndexes[_to][msg.sender]){
      reviews[_to].push(ReviewData({reviewer: msg.sender, comment: _review, rating: _rating}));
      reviewIndexes[_to][msg.sender] = reviews[_to].length - 1;
    }
  }
}
