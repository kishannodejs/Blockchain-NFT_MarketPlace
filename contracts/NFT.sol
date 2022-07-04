//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Locker{

    // function to deposite ETH to contract
    function deposite()public payable{}

    // function withdrawl(uint amount)public returns(bool){
    //     uint _amount = amount * 10 ** 17;
    //     require(_amount < address(this).balance);
    //     payable(msg.sender).transfer(_amount);
    //     return true;
    // }

    // function to withdrawl ETH from contract
    function withdrawl()public returns(bool){
        payable(msg.sender).transfer(((address(this).balance)/100 ) * 80);
        return true;
    }

    // function to check ETH balance of contract
    function getBalance()public view returns(uint){
        return address(this).balance;
    }
}