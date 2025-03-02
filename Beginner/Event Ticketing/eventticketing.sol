//SPDX-License-Identifier:  CC-BY-NC-4.0
// https://spdx.org/licenses/

pragma solidity 0.8.28;

/**
 * @title EventTicketing
 * @dev A smart contract for managing event tickets with
 * creation, purchase, transfer, and refund capabilities
 */
contract EventTicketing {
    //Struct to represent an Event
    //Todo: Choose a better name so you don't clash with keyword event
    struct Event {
        string name;
        uint256 ticketPrice;
        uint256 totalTickets;
        uint256 ticketsSold;
        bool isActive;
        address organizer;
        uint256 eventDeadline; //Timestamp for when the event ends
    }

    //Struct to represent a ticket
    struct Ticket {
        uint256 eventId;
        uint256 ticketId;
        address owner;
        bool isUsed;
        bool exists;
    }

    //State variables
    uint256 private nextEventId = 1;
    mapping(uint256 => Event) public events;
    //eventId => ticketId => Ticket
    mapping(uint256 => mapping(uint256 => Ticket)) public tickets;
    //owner => eventId => ticketIds
    mapping(address => mapping(uint256 => uint256[])) public ticketsOwned;

    //Events
    event EventCreated(
        uint256 indexed eventId,
        string name,
        address organizer,
        uint256 ticketPrice,
        uint256 totalTickets
    );
    event TicketPurchased(
        uint256 indexed eventId,
        uint256 indexed ticketId,
        address buyer,
        uint256 price
    );
    event TicketTransferred(
        uint256 indexed eventId,
        uint256 indexed ticketId,
        address from,
        address to
    );
    event TicketRefunded(
        uint256 indexed eventId,
        uint256 indexed ticketId,
        address owner,
        uint256 refundAmount
    );
    event EventCancelled(uint256 indexed eventId, string reason);

    //Modifiers
    modifier eventExists(uint256 eventId) {
        require(
            events[eventId].organizer != address(0),
            "Event does not exist"
        );
        _;
    }

    modifier onlyOrganizer(uint256 eventId) {
        require(
            events[eventId].organizer == msg.sender,
            "Only the event organizer can call this function"
        );
        _;
    }

    modifier eventActive(uint256 eventId) {
        require(events[eventId].isActive, "Event is not active");
        _;
    }

    modifier ticketExists(uint256 eventId, uint256 ticketId) {
        require(tickets[eventId][ticketId].exists, "Ticket does not exist");
        _;
    }

    modifier onlyTicketOwner(uint256 eventId, uint256 ticketId) {
        require(
            tickets[eventId][ticketId].owner == msg.sender,
            "Only the ticket owner can call this function"
        );
        _;
    }

    /**
     * @dev Creates a new event
     * @param eventName Name of the event
     * @param ticketPrice Price of each ticket in wei
     * @param totalTickets Total number of tickets available
     * @param durationInDays Number of days until the event ends
     * @return eventId The ID of the newly created event
     */
    function createEvent(
        string memory eventName,
        uint256 ticketPrice,
        uint256 totalTickets,
        uint256 durationInDays
    ) public returns (uint256) {
        require(bytes(eventName).length > 0, "Event name cannot be empty");
        require(ticketPrice > 0, "Ticket price must be greater than 0");
        require(totalTickets > 0, "Total tickets must be greater than 0");
        require(durationInDays > 0, "Event duration must be greater than 0");

        uint256 eventId = nextEventId;
        nextEventId++;

        events[eventId] = Event({
            name: eventName,
            ticketPrice: ticketPrice,
            totalTickets: totalTickets,
            ticketsSold: 0,
            isActive: true,
            organizer: msg.sender,
            eventDeadline: block.timestamp + (durationInDays * 1 days)
        });

        emit EventCreated(
            eventId,
            eventName,
            msg.sender,
            ticketPrice,
            totalTickets
        );

        return eventId;
    }

    /**
     * @dev Allows a user to buy a ticket for an event
     * @param eventId ID of the event
     * @return ticketId The ID of the purchased ticket
     */
    function buyTicket(uint256 eventId)
    public 
    payable 
    eventExists(eventId)
    eventActive(eventId)
    returns(uint256)
    {
        Event storage eventInstance = events[eventId];

        require(block.timestamp < eventInstance.eventDeadline, "Event has ended");
        require(eventInstance.ticketsSold < eventInstance.totalTickets, "All tickets have been sold");
        require(msg.value >= eventInstance.ticketPrice, "Insufficient payment");

        //Create ticket
        uint256 ticketId = eventInstance.ticketsSold + 1;
        eventInstance.ticketsSold++;

        //Track ticket ownership
        tickets[eventId][ticketId] = Ticket({
            eventId: eventId,
            ticketId: ticketId,
            owner: msg.sender,
            isUsed: false,
            exists: true
        });

        //Add to owner's tickets
        ticketsOwned[msg.sender][eventId].push(ticketId);

        //Refund excess payment
        uint256 refund = msg.value - eventInstance.ticketPrice;
        if(refund > 0){
            payable (msg.sender).transfer(refund);
        }

        //Transfer payment to organizer
        payable (eventInstance.organizer).transfer(eventInstance.ticketPrice);
        emit TicketPurchased(eventId, ticketId, msg.sender, eventInstance.ticketPrice);
        
        return ticketId;
    }

    



}
