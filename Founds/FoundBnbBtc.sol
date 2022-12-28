//SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "https://github.com/binance-chain/smart-chain/blob/master/contracts/BEP20.sol";
import "https://github.com/binance-chain/smart-chain/blob/master/contracts/SafeMath.sol";

contract Fund {
  using SafeMath for uint256;

  BEP20 public fundToken;  // Moeda do fundo, BUSD-BTC
  address public biSwap;  // DEX BiSwap utilizada para realização de swaps
  address public venus;  // Plataforma Venus utilizada para empréstimos
  uint public annualFee;  // Custódia anual do fundo (em porcentagem)
  uint public entryFee;  // Taxa de entrada do fundo (em porcentagem)
  uint public exitFee;  // Taxa de saída do fundo (em porcentagem)

  // Construtor do contrato, que inicializa as variáveis
  constructor(
    BEP20 _fundToken,
    address _biSwap,
    address _venus,
    uint _annualFee,
    uint _entryFee,
    uint _exitFee
  ) public {
    fundToken = _fundToken;
    biSwap = _biSwap;
    venus = _venus;
    annualFee = _annualFee;
    entryFee = _entryFee;
    exitFee = _exitFee;
  }

  // Função para permitir que usuários adicionem saldo ao fundo
  function addFunds(uint256 amount) public {
    require(msg.sender.send(amount), "Transferência falhou");  // Verifica se a transferência foi bem-sucedida
    fundToken.transfer(msg.sender, amount);  // Transfere a quantidade especificada para o endereço do usuário
  }

  // Função para permitir que usuários retirem saldo do fundo
  function withdrawFunds(uint256 amount) public {
    require(fundToken.balanceOf(msg.sender) >= amount, "Saldo insuficiente");  // Verifica se o usuário tem saldo suficiente
    require(fundToken.transfer(msg.sender, amount), "Transferência falhou");  // Verifica se a transferência foi bem-sucedida
  }

    // Função para permitir que o fundo empreste 50% do saldo na Venus
  function lendOnVenus() public {
    uint balance = fundToken.balanceOf(address(this));  // Verifica o saldo atual do fundo
    uint amountToLend = balance.div(2);  // Calcula a quantidade a ser emprestada (50% do saldo)
    require(venus.call(bytes4(keccak256("lend(uint256)")), amountToLend), "Emprestimo falhou");  // Verifica se o empréstimo foi bem-sucedido
  }

  // Função para permitir que usuários entrem no fundo, pagando a taxa de entrada
  function joinFund() public payable {
    uint entryFeeAmount = msg.value.mul(entryFee).div(100);  // Calcula o valor da taxa de entrada
    require(msg.value >= entryFeeAmount, "Valor da entrada insuficiente");  // Verifica se o valor pago é suficiente para cobrir a taxa de entrada
    fundToken.transfer(msg.sender, msg.value.sub(entryFeeAmount));  // Transfere o valor restante para o endereço do usuário
  }

  // Função para permitir que usuários saiam do fundo, pagando a taxa de saída
  function exitFund() public {
    uint balance = fundToken.balanceOf(msg.sender);  // Verifica o saldo atual do usuário no fundo
    uint exitFeeAmount = balance.mul(exitFee).div(100);  // Calcula o valor da taxa de saída
    require(balance >= exitFeeAmount, "Saldo insuficiente para cobrir taxa de saída");  // Verifica se o saldo é suficiente para cobrir a taxa de saída
    fundToken.transfer(msg.sender, balance.sub(exitFeeAmount));  // Transfere o saldo restante para o endereço do usuário
  }

  // Função para permitir que o fundo cobre a custódia anual dos usuários
  function chargeAnnualFee() public {
    uint totalSupply = fundToken.totalSupply();  // Verifica o total de tokens do fundo
    uint annualFeeAmount = totalSupply.mul(annualFee).div(100);  // Calcula o valor da custódia anual
    fundToken.transfer(address(this), annualFeeAmount);  // Transfere o valor da custódia anual para o fundo
  }
}