#!/bin/bash
# To configure home
export HOME=/root

# To install the jq package
echo To install the jq package
sudo apt-get update
sudo apt install -y jq

# To install chain-maind on Testnet
curl -LOJ https://github.com/crypto-org-chain/chain-main/releases/download/v3.0.0-croeseid/chain-main_3.0.0-croeseid_Linux_x86_64.tar.gz
tar -zxvf chain-main_3.0.0-croeseid_Linux_x86_64.tar.gz

# To initiate chain-maind
chain-maind init testnodeA --chain-id testnet-croeseid-4

# To update the genesis file
curl https://raw.githubusercontent.com/crypto-com/testnets/main/testnet-croeseid-4/genesis.json > ~/.chain-maind/config/genesis.json

# To update minimum gas price to avoid transaction spamming
sudo sed -i.bak -E 's#^(minimum-gas-prices[[:space:]]+=[[:space:]]+)""$#\1"0.025basetcro"#' ~/.chain-maind/config/app.toml

# To update network settings
sed -i.bak -E 's#^(persistent_peers[[:space:]]+=[[:space:]]+).*$#\1"71d2a4727bf574d5d368c343e37edff00cd556b1@52.76.52.229:26656,8af7c92277f3edce58aa828cf1026cfa74fd6569@18.141.249.17:26656"#' ~/.chain-maind/config/config.toml
sed -i.bak -E 's#^(create_empty_blocks_interval[[:space:]]+=[[:space:]]+).*$#\1"5s"#' ~/.chain-maind/config/config.toml
sed -i.bak -E 's#^(timeout_commit[[:space:]]+=[[:space:]]+).*$#\1"2s"#' ~/.chain-maind/config/config.toml

# To enable Tendermint rpc
sed -i 's/127.0.0.1:26657/0.0.0.0:26657/g' ~/.chain-maind/config/config.toml

# To enable Cosmos rpc
sed -i '0,/\(^enable =\).*/{s/\(^enable =\).*/\1 true/}' ~/.chain-maind/config/app.toml

# To enable STATE-SYNC
LATEST_HEIGHT=$(curl -s https://testnet-croeseid-4.crypto.org:26657/block | jq -r .result.block.header.height); \
BLOCK_HEIGHT=$((LATEST_HEIGHT - 1000)); \
TRUST_HASH=$(curl -s "https://testnet-croeseid-4.crypto.org:26657/block?height=$BLOCK_HEIGHT" | jq -r .result.block_id.hash)

sed -i.bak -E "s|^(enable[[:space:]]+=[[:space:]]+).*$|\1true| ; \
s|^(rpc_servers[[:space:]]+=[[:space:]]+).*$|\1\"https://testnet-croeseid-4.crypto.org:26657,https://testnet-croeseid-4.crypto.org:26657\"| ; \
s|^(trust_height[[:space:]]+=[[:space:]]+).*$|\1$BLOCK_HEIGHT| ; \
s|^(trust_hash[[:space:]]+=[[:space:]]+).*$|\1\"$TRUST_HASH\"| ; \
s|^(seeds[[:space:]]+=[[:space:]]+).*$|\1\"\"|" ~/.chain-maind/config/config.toml

# To setup chain-maind as systemd service
git clone https://github.com/crypto-org-chain/chain-main.git && cd chain-main
./networks/create-service.sh
cat ./networks/chain-maind.service >>  /var/log/syslog
sed -i 's/User=/User=root/' ./networks/chain-maind.service
cat ./networks/chain-maind.service >>  /var/log/syslog
sudo cp ./networks/chain-maind.service /etc/systemd/system/chain-maind.service
sudo systemctl daemon-reload
sudo systemctl enable chain-maind.service
sudo systemctl start chain-maind

