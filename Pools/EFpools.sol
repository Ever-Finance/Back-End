//SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

struct User {
  address userAddress;
  uint balance;
}

mapping (address => User) public users;
uint public contractBalance;

// Estrutura de dados para armazenar informações sobre as moedas
struct Currency {
  string name;
  uint balance;
  uint exchangeRate; // Taxa de câmbio em relação à outra moeda
}

// Mapeamento para armazenar informações sobre as moedas
mapping (string => Currency) public currencies;

function addLiquidity(uint amount, string currency) public {
  // Verifica se a moeda é válida
  require(currencies[currency].balance > 0, "Moeda inválida");
  // Atualiza o saldo do usuário
  users[msg.sender].balance += amount;
  // Credita a quantidade de liquidez adicionada ao contrato
  currencies[currency].balance += amount;
}

function removeLiquidity(uint amount, string currency) public {
  // Verifica se a moeda é válida
  require(currencies[currency].balance > 0, "Moeda inválida");
  // Verifica se o usuário tem saldo suficiente
  require(users[msg.sender].balance >= amount, "Saldo insuficiente");
  // Atualiza o saldo do usuário
  users[msg.sender].balance -= amount;
  // Debita a quantidade de liquidez retirada do contrato
  currencies[currency].balance -= amount;
}

function exchange(uint amount, string currencyFrom, string currencyTo) public {
  // Verifica se as moedas são válidas
  require(currencies[currencyFrom].balance > 0, "Moeda de origem inválida");
  require(currencies[currencyTo].balance > 0, "Moeda de destino inválida");
  // Verifica se o usuário tem saldo suficiente
  require(users[msg.sender].balance >= amount, "Saldo insuficiente");

  // Calcula a quantidade de moeda de destino que será recebida na troca com base na taxa de câmbio
  uint exchangeAmount = amount.mul(currencies[currencyTo].exchangeRate).div(currencies[currencyFrom].exchangeRate);

  // Atualiza o saldo do usuário
  users[msg.sender].balance -= amount;
  users[msg.sender].balance += exchangeAmount;

// Atualiza os totais de moedas
currencies[currencyFrom].balance -= amount;
currencies[currencyFrom].totalSupply -= amount;
currencies[currencyTo].balance += exchangeAmount;
currencies[currencyTo].totalSupply += exchangeAmount;

// Dispara o evento de troca
emit Exchange(msg.sender, amount, currencyFrom, exchangeAmount, currencyTo);
}