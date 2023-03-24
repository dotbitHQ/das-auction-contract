# Overview

This contract is used for the dutch auction to sale expired .bit account

# Prerequisites
nodejs >= 19.7

# Install & Run
```shell
npm install --save-dev hardhat
npm install --save-dev @openzeppelin/hardhat-upgrades
npx hardhat
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
