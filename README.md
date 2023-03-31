# Overview

This contract is used for the dutch auction to sale expired .bit account

# Prerequisites
ubuntu >= 20.04

nodejs >= 19.*
```shell
apt install sudo
apt install curl
curl -sL https://deb.nodesource.com/setup_19.x | sudo -E bash -
sudo apt install -y nodejs

sudo apt install build-essential
```

# Install & Run
```shell
npm install --save-dev hardhat
npm install --save-dev @openzeppelin/contracts-upgradeable
npm install --save-dev @openzeppelin/contracts
npm install --save-dev @openzeppelin/hardhat-upgrades
```

# Test
```shell
npx hardhat test
```
# Deploy
```shell
npx hardhat run --network goerli  ./scripts/deploy.js 
```
# Upgrade
```shell
npx hardhat run --network goerli ./scripts/upgrade.js
```
