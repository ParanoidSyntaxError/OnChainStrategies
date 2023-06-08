const connectButton = document.getElementById("btn-connect");
connectButton.onclick = connect;

const Web3Modal = window.Web3Modal.default;
const WalletConnectProvider = window.WalletConnectProvider.default;
const Fortmatic = window.Fortmatic;
const evmChains = window.evmChains;

let web3Modal;
let web3Provider;
let web3;

let ocsAbi;
let ocsContract;

let erc20Abi
let aggregatorV3Abi;

var web3Addresses;

initialize();

const onConnected = new Event("connected");
const onNetworkChanged = new Event("networkChanged");
var web3Events = document.createElement(null);

async function initialize() {
	const addresses = await fetch("../data/addresses.json");
	web3Addresses = await addresses.json();

	const ocs_abi = await fetch("../data/ocs_abi.json");
    ocsAbi = await ocs_abi.json();

	const erc20_abi = await fetch("../data/erc20_abi.json");
    erc20Abi = await erc20_abi.json();

	const aggregatorV3_abi = await fetch("../data/aggregatorV3_abi.json");
    aggregatorV3Abi = await aggregatorV3_abi.json();

	const providerOptions = {
		walletconnect: {
			package: WalletConnectProvider
		},
		fortmatic: {
			package: Fortmatic
		}
	};

	web3Modal = new Web3Modal({
		cacheProvider: false,
		providerOptions,
		disableInjectedProvider: false,
	});
}

async function connect() {
	web3Provider = await web3Modal.connect();
		
	web3Provider.addListener("accountsChanged", () => {
		getWeb3();
		displayConnection();
	});
	
	web3Provider.addListener("chainChanged", () => {
		getWeb3();
		web3Events.dispatchEvent(onNetworkChanged);
	});

	getWeb3();
	displayConnection();
	web3Events.dispatchEvent(onNetworkChanged);
}

function getWeb3() {
	web3 = new ethers.providers.Web3Provider(web3Provider);
	chainData = evmChains.getChain(parseInt(web3Provider.chainId));
	
	if(isOnSupportedNetwork()) {
		ocsContract = new ethers.Contract(web3Addresses["contracts"][getChainId()]["OCS"], ocsAbi, getConnectedSigner());
		web3Events.dispatchEvent(onConnected);
	} else {
		// Wrong network
	}
}

async function displayConnection() {
    if(getConnectedSigner() != undefined) {
		connectButton.innerHTML = getConnectedAddress().toString().slice(0, 5) + "..." + getConnectedAddress().toString().slice(38, 42);
		connectButton.disabled = true;
		
	} else {
		connectButton.innerHTML = "Connect";
		connectButton.disabled = false;
	}
}

function isOnSupportedNetwork() {
	return chainData.chainId == 137 || chainData.chainId == 80001;
}

function getChainId() {
	return String(parseInt(web3Provider.chainId));
}

function getConnectedSigner() {
	return web3.getSigner();
}

function getConnectedAddress() {
	return web3Provider.selectedAddress;
}

async function getLatestTimestamp() {
  	const timestamp = (await web3.getBlock('latest')).timestamp;
	return timestamp;
}

async function getLatestRoundId(aggregatorAddress) {
	const aggregator = new ethers.Contract(aggregatorAddress, aggregatorV3Abi, getConnectedSigner());
	return BigInt((await aggregator.latestRoundData())[0]);
}

async function tokenApproval(tokenAddress, amount) {
	try {
		const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, getConnectedSigner());
		const receipt = await tokenContract.approve(web3Addresses["contracts"][getChainId()]["OCS"], amount);
		const txn = await receipt.wait();
		return true;
	} catch {
		return false;
	}
}

async function tokenAllowance(tokenAddress) {
	const tokenContract = new ethers.Contract(tokenAddress, erc20Abi, getConnectedSigner());
	return BigInt(await tokenContract.allowance(getConnectedAddress(), web3Addresses["contracts"][getChainId()]["OCS"]));
}

async function mint(strategyType, recepient, approved, baseStrategy, data) {
	if(strategyType == 0) {
		// Interval
		data = ethers.utils.AbiCoder.prototype.encode(
			['uint256', 'uint256'],
			[data.interval, data.lastTimestamp]
		);
	} else if(strategyType == 1 || strategyType == 2) {
		// Data feed change
		data = ethers.utils.AbiCoder.prototype.encode(
			['address', 'int256', 'uint80', 'uint80'],
			[data.aggregator, data.change, data.lastRoundId, data.frequency]
		);
	}

	const receipt = await ocsContract.mint(strategyType, recepient, approved, baseStrategy, data);
	const txn = await receipt.wait();
	return txn;
}