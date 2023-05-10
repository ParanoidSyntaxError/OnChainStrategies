const infoTarotTitle = document.getElementById("tarot-info-title");
const infoTarotBody = document.getElementById("tarot-info-body");

let infoTarots = document.getElementsByName("info-tarot");

let selectedInfoTarot = Math.floor(Math.random() * 3);

initialize();

function initialize() {
    // Tarot info cards
    for(let i = 0; i < infoTarots.length; i++) {
        infoTarots[i].classList.add("info-tarot-unselected");
        
        infoTarots[i].addEventListener("click", () => {
            infoTarots[selectedInfoTarot].classList.remove("info-tarot-selected");
            infoTarots[selectedInfoTarot].classList.add("info-tarot-unselected");

            infoTarots[i].classList.remove("info-tarot-unselected");
            infoTarots[i].classList.add("info-tarot-selected");

            selectInfoTarot(i);
        });
    }

    selectInfoTarot(selectedInfoTarot);
    infoTarots[selectedInfoTarot].classList.remove("info-tarot-unselected");
    infoTarots[selectedInfoTarot].classList.add("info-tarot-selected");
}

function selectInfoTarot(index) {
    selectedInfoTarot = index;

    switch(index) {
        case 0:
            infoTarotTitle.innerHTML = "Chainlink Automation";
            infoTarotBody.innerHTML = "Automation executes strategies quickly, and in a decentralized manner";
            break;
        case 1:
            infoTarotTitle.innerHTML = "Chainlink Data Feeds";
            infoTarotBody.innerHTML = "Data feeds give strategies access to decentralized, off-chain data";
            break;
        case 2:
            infoTarotTitle.innerHTML = "Uniswap V3 Pools";
            infoTarotBody.innerHTML = "Trade against Uniswap's latest liquidity pools, for the lowest transfer fees";
            break;
    }
}