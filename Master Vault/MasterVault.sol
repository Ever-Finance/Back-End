//Pragma
pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/utils/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/7f6a1666fac8ecff5dd467d0938069bc221ea9e0/contracts/token/ERC20/utils/SafeERC20.sol";

// Identificador de licença
//SPDX-License-Identifier: MIT

// Contrato EFTStaking
contract EFTStaking {
    // Importe a biblioteca SafeMath
    using SafeMath for uint256;

    // Mapeamento que armazena o saldo de tokens em stake de cada staker
    mapping(address => uint256) public stakes;

    // Variável que armazena o total de tokens em stake
    uint256 public totalStake;

    // Endereço do contrato de token da plataforma
    address public platformTokenAddress;

    // Construtor
    constructor(address _platformTokenAddress) public {
        platformTokenAddress = 0xa2198Ec5E96E918C251bdD298cC337C5F799833e;
    }

    // Essa função tem o objetivo de adicionar tokens em stake
    function stake(uint256 amount) public {
        // Verifique se o valor é positivo
        require(amount > 0, "O valor deve ser positivo");

        // Verifique se o remetente da transação tem saldo suficiente
        // para realizar a operação
        require(ERC20(platformTokenAddress).balanceOf(msg.sender) >= amount, "Saldo insuficiente");

        // Atualize o saldo do staker e o total de tokens em stake
        stakes[msg.sender] = stakes[msg.sender].add(amount);
        totalStake = totalStake.add(amount);

        // Emita um evento para registrar a adição de tokens em stake
        emit Staked(msg.sender, amount);
    }

    // Essa função tem o objetivo de remover tokens em stake
    function unstake(uint256 amount) public {
        // Verifique se o staker tem saldo suficiente para realizar a operação
        require(stakes[msg.sender] >= amount, "Saldo insuficiente");

        // Atualize o saldo do staker e o total de tokens em stake
        stakes[msg.sender] = stakes[msg.sender].sub(amount);
        totalStake = totalStake.sub(amount);

        // Emita um evento para registrar a remoção de tokens em stake
        emit Unstaked(msg.sender, amount);
    }

    // Essa função tem o objetivo de distribuir as recompensas para os stakers
    function distributeStakeRewards(uint256 value) public {
        // Verifique se o valor é positivo
        require(value > 0, "O valor deve ser positivo");

        // Obtenha a lista de endereços que têm tokens em stake
        address[] stakers = getStakers();

        // Obtenha o número de tokens em stake de cada staker
        uint256[] stakeAmounts = new uint256[](stakers.length);
        for (uint i = 0; i < stakers.length; i++) {
            stakeAmounts[i] = getStakeAmount(stakers[i]);
        }

        // Distribua os valores proporcionalmente aos tokens em stake
        for (uint i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 stakeAmount = stakeAmounts[i];
            uint256 reward = value * stakeAmount / totalStake;
            staker.transfer(reward);
        }

        // Emita um evento para registrar a distribuição de recompensas
        emit RewardsDistributed(value);
    }

    // Essa função tem o objetivo de resgatar as recompensas
    // sem retirar os tokens em stake
    function withdrawRewards() public {
        // Verifique se o staker tem saldo de recompensas
        require(stakes[msg.sender] > 0, "Saldo de recompensas insuficiente");

        // Retire as recompensas do staker
        uint256 rewards = stakes[msg.sender];
        stakes[msg.sender] = 0;

        // Emita um evento para registrar o resgate de recompensas
        emit RewardsWithdrawn(msg.sender, rewards);
    }

    // Essa função tem o objetivo de redistribuir recompensas não resgatadas
    // após um período de 1 década
    function redistributeExpiredRewards() public {
        // Obtenha a lista de stakers
        address[] stakers = getStakers();

        // Obtenha o saldo de recompensas não resgatadas de cada staker
        uint256[] rewardAmounts = new uint256[](stakers.length);
        for (uint i = 0; i < stakers.length; i++) {
            rewardAmounts[i] = stakes[stakers[i]];
        }

        // Calcule o total de recompensas não resgatadas
        uint256 totalExpiredRewards = 0;
        for (uint i = 0; i < stakers.length; i++) {
            totalExpiredRewards = totalExpiredRewards.add(rewardAmounts[i]);
        }

        // Verifique se existem recompensas não resgatadas
        require(totalExpiredRewards > 0, "Nao ha recompensas nao resgatadas para redistribuir");

        // Redistribua as recompensas não resgatadas para os stakers
        for (uint i = 0; i < stakers.length; i++) {
            address staker = stakers[i];
            uint256 rewardAmount = rewardAmounts[i];
            uint256 reward = rewardAmount * totalStake / totalExpiredRewards;
            staker.transfer(reward);
        }

        // Emita um evento para registrar a redistribuição de recompensas
        emit RewardsRedistributed(totalExpiredRewards);
    }

    // Essa função tem o objetivo de obter a lista de stakers
    function getStakers() public view returns (address[] memory) {
        // Inicialize uma lista vazia
        address[] memory stakers = new address[](0);

        // Percorra o mapeamento de stakes e adicione os stakers à lista
        for (address staker in stakes) {
            if (stakes[staker] > 0) {
                stakers.push(staker);
            }
        }

        // Retorne a lista de stakers
        return stakers;
    }

    // Essa função tem o objetivo de obter o número de tokens em stake de um staker
    function getStakeAmount(address staker) public view returns (uint256) {
        return stakes[staker];
    }
}