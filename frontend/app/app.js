const selectTokenIn = document.getElementById("select-token-in");
const selectTokenOut = document.getElementById("select-token-out");

const customTokenInParent = document.getElementById("div-custom-token-in");
selectTokenIn.addEventListener("change", () => {
    if(selectTokenIn.value == "custom") {
        customTokenInParent.hidden = false;
    } else {
        customTokenInParent.hidden = true;
    }
});

const customTokenOutParent = document.getElementById("div-custom-token-out");
selectTokenOut.addEventListener("change", () => {
    if(selectTokenOut.value == "custom") {
        customTokenOutParent.hidden = false;
    } else {
        customTokenOutParent.hidden = true;
    }
});

const intervalParams = document.getElementById("div-interval-params");
const flatParams = document.getElementById("div-flat-params");
const percentParams = document.getElementById("div-percent-params");

const flatCustomOracleParent = document.getElementById("div-flat-custom-oracle");
const percentCustomOracleParent = document.getElementById("div-percent-custom-oracle");

const intervalInput = document.getElementById("input-interval");

const selectFlatOracle = document.getElementById("select-flat-oracle");
selectFlatOracle.addEventListener("change", () => {
    if(selectFlatOracle.value == "custom") {
        flatCustomOracleParent.hidden = false;
    } else {
        flatCustomOracleParent.hidden = true;
    }
});

const selectPercentOracle = document.getElementById("select-percent-oracle");
selectPercentOracle.addEventListener("change", () => {
    if(selectPercentOracle.value == "custom") {
        percentCustomOracleParent.hidden = false;
    } else {
        percentCustomOracleParent.hidden = true;
    }
});

const selectStrategyType = document.getElementById("select-strategy-type");
selectStrategyType.addEventListener("change", () => {
    intervalParams.hidden = true;
    flatParams.hidden = true;
    percentParams.hidden = true;
    let strategyType = parseInt(selectStrategyType.value);
    switch(strategyType) {
        case 0:
            intervalParams.hidden = false;
            break;
        case 1:
            flatParams.hidden = false;
            break;
        case 2:
            percentParams.hidden = false;
            break;
    }
});

const swapAmountInput = document.getElementById("input-swap-amount");
const allocationInput = document.getElementById("input-allocation");

const flatChangeInput = document.getElementById("input-flat-change");
const flatFrequencyInput = document.getElementById("input-flat-frequency");

const percentChangeInput = document.getElementById("input-percent-change");
const percentFrequencyInput = document.getElementById("input-percent-frequency");

let allocationApproved = false;

const approveButton = document.getElementById("btn-approve");
approveButton.addEventListener("click", async () => {
    const amount = await tokenAllowance(selectTokenIn.value) + BigInt(allocationInput.value);
    let success = await tokenApproval(selectTokenIn.value, amount);
    if(success == true) {
        mintButton.disabled = false;
        approveButton.disabled = true;
    }
});

const mintButton = document.getElementById("btn-mint");
mintButton.addEventListener("click", async () => {
    let strategyType = parseInt(selectStrategyType.value);

    let baseStrategy = {
        tokenIn : selectTokenIn.value,
        tokenOut : selectTokenOut.value,
        amount : swapAmountInput.value,
        poolFee : 3000,
        allocation : allocationInput.value
    };

    let data;

    switch(strategyType) {
        // Interval
        case 0:
            const latestTimestamp = await getLatestTimestamp();
            data = {
                interval : intervalInput.value,
                lastTimestamp : latestTimestamp
            };
            break;
        case 1:
            data = {
                aggregator : selectFlatOracle.value,
                change : flatChangeInput.value,
                lastRoundId : (await getLatestRoundId(selectFlatOracle.value)).toString(),
                frequency : flatFrequencyInput.value
            };
            break;
        case 2:
            const change = percentChangeInput.value * 100;
            data = {
                aggregator : selectPercentOracle.value,
                change : change,
                lastRoundId : (await getLatestRoundId(selectPercentOracle.value)).toString(),
                frequency : percentFrequencyInput.value
            };
            break;
    }
    
    const txn = await mint(strategyType, getConnectedAddress(), true, baseStrategy, data);
});

web3Events.addEventListener("networkChanged", async () => {
    const oracles = web3Addresses["oracles"][getChainId()];
    for(let i = 0; i < oracles.length; i++) {
        let option = document.createElement("option");
        option.innerHTML = oracles[i].label;
        option.value = oracles[i].address;
        selectFlatOracle.add(option);

        option = document.createElement("option");
        option.innerHTML = oracles[i].label;
        option.value = oracles[i].address;
        selectPercentOracle.add(option);
    }

    const tokens = web3Addresses["tokens"][getChainId()];
    for(let i = 0; i < tokens.length; i++) {
        let option = document.createElement("option");
        option.innerHTML = tokens[i].label;
        option.value = tokens[i].address;
        selectTokenIn.add(option);

        option = document.createElement("option");
        option.innerHTML = tokens[i].label;
        option.value = tokens[i].address;
        selectTokenOut.add(option);
    }
});