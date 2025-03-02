//SPDX-License-Identifier:  CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

/**  
* @title EventTicketing  
* @dev A smart contract for managing event tickets with
* creation, purchase, transfer, and refund capabilities  
*/ 
contract EventTicketing
{
    //Struct to represent an Event
    //Todo: Choose a better name so you don't clash with keyword event
    struct Event
    {
        string name;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
        bool isActive;
        address organizer;
        uint256 eventDeadline;//Timestamp for when the event ends
    }

    //Struct to represent a ticket
    struct Ticket
    {
        uint256 eventId;
        uint256 ticketId;
        address owner;
        bool isUsed;
        bool exists;
    }

    //State variables
    uint256 private nextEventId = 1;
    mapping(uint256 => Event)public events;
    //eventId => ticketId => Ticket
    mapping(uint256 => mapping(uint256 => Ticket))public tickets;
    //owner => eventId => ticketIds
    mapping(address =>mapping(uint256 => uint256[]))public ticketsOwned;

    //Events
    event EventCreated(uint256 indexed eventId, string name, address organizer,
        uint256 ticketPrice, uint256 totalTickets);
    event TicketPurchased(uint256 indexed eventId, uint256 indexed ticketId,
        address buyer, uint256 price);
    event TicketTransferred(uint256 indexed eventId, uint256 indexed ticketId,
        address from, address to);
    event TicketRefunded(uint256 indexed eventId, uint256 indexed ticketId, 
        address owner, uint256 refundAmount);
    event EventCancelled(uint256 indexed eventId, string reason);

    //Modifiers
    modifier eventExists(uint256 eventId)
    {
        require(events[eventId].organizer != address(0), "Event does not exist");
        _;
    }

    modifier onlyOrganizer(uint256 eventId)
    {
        require(events[eventId].organizer == msg.sender, "Only the event organizer can call this function");
        _;
    }

    modifier eventActive(uint256 eventId)
    {
        require(events[eventId].isActive, "Event is not active");
        _;
    }

    modifier ticketExists(uint256 eventId, uint256 ticketId)
    {
        require(tickets[eventId][ticketId].exists, "Ticket does not exist");
        _;
    }

    modifier onlyTicketOwner(uint256 eventId, uint256 ticketId)
    {
        require(tickets[eventId][ticketId].owner == msg.sender, "Only the ticket owner can call this function");
        _;
    }

    


}