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
    switch(selectStrategyType.value) {
        case "interval":
            intervalParams.hidden = false;
            break;
        case "flat":
            flatParams.hidden = false;
            break;
        case "percent":
            percentParams.hidden = false;
            break;
    }
});

let addresses;

initialize();

async function initialize() {
    const response = await fetch("../addresses.json");
    addresses = await response.json();

    const oracles = addresses["oracles"]["mumbai"];
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

    const tokens = addresses["tokens"]["mumbai"];
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
}