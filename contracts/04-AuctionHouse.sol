// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AuctionHouse {
    // Estado de la subasta
    uint public highestBid;
    address public highestBidder;
    uint public auctionEndTime;
    address payable public beneficiary;

    // Eventos para notificar la actividad
    event HighestBidIncreased(address bidder, uint amount);
    event AuctionEnded(address winner, uint amount);

    // Constructor: Establece la duración de la subasta
    constructor(uint _biddingTime) payable {
        beneficiary = payable(msg.sender);
        // Usa block.timestamp para calcular la hora de finalización
        auctionEndTime = block.timestamp + _biddingTime;
    }

    // Función para pujar
    function bid() public payable {
        // Control de tiempo: Revertir si la subasta terminó
        if (block.timestamp >= auctionEndTime) {
            revert("Auction already ended.");
        }

        // Control de la puja: Revertir si no supera la puja actual
        if (msg.value <= highestBid) {
            revert("Bid must be higher than the current highest bid.");
        }

        // Lógica de reembolso: Envía el Ether de vuelta al anterior postor
        if (highestBidder != address(0)) {
            (bool success, ) = highestBidder.call{value: highestBid}("");
            require(success, "Refund to previous bidder failed.");
        }

        // Actualiza el estado con la nueva puja más alta
        highestBidder = msg.sender;
        highestBid = msg.value;

        emit HighestBidIncreased(msg.sender, msg.value);
    }

    // Función para finalizar la subasta y declarar al ganador
    function endAuction() public {
        // Control de tiempo: Revertir si la subasta no ha terminado
        if (block.timestamp < auctionEndTime) {
            revert("Auction is still active.");
        }
        
        // Evita que se llame dos veces o que no haya habido pujas
        if (highestBidder == address(0)) {
            revert("Auction already concluded or no bids placed.");
        }
        
        // Transfiere el balance total del contrato al beneficiario
        uint amountToSend = address(this).balance;

        (bool success, ) = beneficiary.call{value: amountToSend}("");
        
        require(success, "Transfer to beneficiary failed.");

        emit AuctionEnded(highestBidder, highestBid);

        // Limpia el estado para evitar re-llamadas
        highestBidder = address(0);
    }
}