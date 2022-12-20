pragma solidity ^0.8.7;

import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol";
import "https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

// Identificador de licença
//SPDX-License-Identifier: MIT

// Cláusula de pragma
pragma solidity ^0.8.7;

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
        platformTokenAddress = _platformTokenAddress;
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
        // Obtenha o saldo de recompensas do staker
        uint256 rewardBalance = ERC20(platformTokenAddress).balanceOf(address(this));

        // Verifique se o staker tem saldo de recompensas para resgatar
        require(rewardBalance > 0, "Saldo de recompensas insuficiente");

        // Transfira as recompensas para o staker
        ERC20(platformTokenAddress).transfer(msg.sender, rewardBalance);

        // Emita um evento para registrar o resgate de recompensas
        emit RewardsWithdrawn(msg.sender, rewardBalance);
    }

    // Essa função tem o objetivo de redistribuir as recompensas
    // se elas não forem resgatadas após 1 década
    function redistributeRewards() public {
        // Verifique se o contrato tem saldo de recompensas para redistribuir
        uint256 rewardBalance = ERC20(platformTokenAddress).balanceOf(address(this));
        require(rewardBalance > 0, "Nao ha recompensas para redistribuir");

        // Distribua as recompensas para os stakers
        distributeStakeRewards(rewardBalance);
    }

    // Essa função tem o objetivo de obter a lista de endereços que têm tokens em stake
    function getStakers() public view returns (address[] memory) {
        // Inicialize a lista de stakers
        address[] memory stakers = new address[](stakes.length);

        // Preencha a lista de stakers
        uint i = 0;
        for (address staker = stakes.keys(); staker != address(0); staker = stakes.nextKey(staker)) {
            stakers[i] = staker;
            i++;
        }
            // Retorne a lista de stakers
        return stakers;
    }

    // Essa função tem o objetivo de obter o número de tokens em stake de um staker
    function getStakeAmount(address staker) public view returns (uint256) {
        // Retorne o saldo de tokens em stake do staker
        return stakes[staker];
    }

    // Evento para registrar a adição de tokens em stake
    event Staked(address staker, uint256 amount);

    // Evento para registrar a remoção de tokens em stake
    event Unstaked(address staker, uint256 amount);

    // Evento para registrar a distribuição de recompensas
    event RewardsDistributed(uint256 value);

    // Evento para registrar o resgate de recompensas
    event RewardsWithdrawn(address staker, uint256 amount);
}