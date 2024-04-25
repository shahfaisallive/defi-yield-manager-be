require('dotenv').config();
const Web3 = require('web3');
const nodeCron = require('node-cron');

// Setup web3 provider
const web3 = new Web3(new Web3.providers.HttpProvider(`https://sepolia.infura.io/v3/${process.env.INFURA_PROJECT_ID}`));

// Contract setup
const positionManagerABI = require('./abi/PositionManager.json');
const positionManagerAddress = process.env.POSITION_MANAGER_ADDRESS;
const positionManager = new web3.eth.Contract(positionManagerABI, positionManagerAddress);

const account = web3.eth.accounts.privateKeyToAccount(`0x${process.env.PRIVATE_KEY}`);
web3.eth.accounts.wallet.add(account);

// Scheduled task to adjust liquidity based on market conditions
nodeCron.schedule('* * * * *', async function() {
    console.log('Running every minute');

    // Function to update liquidity
    const updateFunction = positionManager.methods.updateLiquidityParameters();
    const gas = await updateFunction.estimateGas({from: account.address});
    const gasPrice = await web3.eth.getGasPrice();
    const data = updateFunction.encodeABI();
    const nonce = await web3.eth.getTransactionCount(account.address);

    const signedTx = await web3.eth.accounts.signTransaction({
        to: positionManagerAddress,
        data,
        gas,
        gasPrice,
        nonce,
        chainId: 1
    }, account.privateKey);

    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);
    console.log('Transaction receipt:', receipt);
});
