//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.7;

contract EFTStaking {
    // Tipo de dados para representar uma entrada de stake de um usuário
    struct Stake {
        address payable owner; // endereço do proprietário do stake
        uint256 amount; // quantidade de tokens EFT em stake
        uint256 lastClaimTime; // último momento em que o usuário reclamou seus tokens TBNB
    }

    // Mapeia cada endereço para sua entrada de stake
    mapping(address => Stake) public stakes;

    // Quantidade total de tokens EFT em stake
    uint256 public totalStakedAmount;

    // Quantidade total de tokens TBNB disponíveis
    uint256 public totalTBNBAmount;

    // Evento disparado quando um novo stake é adicionado
    event Staked(address indexed owner, uint256 amount);

    // Evento disparado quando um stake é removido
    event Unstaked(address indexed owner, uint256 amount);

    // Evento disparado quando tokens TBNB são distribuídos
    event TBNBDistributed(address indexed owner, uint256 amount);

    // Adiciona um novo stake de tokens EFT
    function stake(uint256 amount) public payable {
        require(msg.value == amount, "O valor enviado deve ser igual a quantidade de tokens EFT em stake");

        // Atualiza a entrada de stake do usuário
        Stake storage stake = stakes[msg.sender];
        stake.amount += amount;
        stake.lastClaimTime = block.timestamp;

        // Atualiza a quantidade total de tokens EFT em stake
        totalStakedAmount += amount;

        // Dispara o evento Staked
        emit Staked(msg.sender, amount);
    }

    // Remove um stake de tokens EFT
    function unstake(uint256 amount) public {
        Stake storage stake = stakes[msg.sender];
        require(stake.amount >= amount, "Voce nao tem tokens EFT suficientes em stake");

        // Atualiza a entrada de stake do usuário
        stake.amount -= amount;

        // Atualiza a quantidade total de tokens EFT em stake
        totalStakedAmount -= amount;

        // Dispara o evento Unstaked
        emit Unstaked(msg.sender, amount);

        // Envia os tokens EFT de volta para o usuário
        msg.sender.transfer(amount);
    }

    // Reclama os tokens TBNB que o usuário tem direito com base em seu stake de tokens EFT
    function claim() public {
        // Recupera a entrada de stake do usuário
        Stake storage stake = stakes[msg.sender];
        // Verifica se o usuário possui tokens EFT em stake
        require(stake.amount > 0, "Voce nao tem tokens EFT em stake");

        // Calcula a quantidade de tokens TBNB a ser distribuída para o usuário com base em sua participação no staking
        uint256 tokensToClaim = stake.amount * totalTBNBAmount / totalStakedAmount;

        // Atualiza a última vez que o usuário reclamou tokens TBNB
        stake.lastClaimTime = now;

        // Atualiza a quantidade total de tokens TBNB disponíveis
        totalTBNBAmount -= tokensToClaim;

        // Dispara o evento TBNBDistributed
        emit TBNBDistributed(msg.sender, tokensToClaim);

        // Envia os tokens TBNB para o usuário
        msg.sender.transfer(tokensToClaim);
    }
}