#!/bin/bash

# Fast transaction bomb - 1000 transactions to random accounts
NUM_TXS=1000
AMOUNT="1000000000000000000atest" # 1 NOWA
CHAIN_ID="9001"
NODE="tcp://localhost:26657"
FROM_KEY="dev0"

echo "🚀 Fast Transaction Bomb"
echo "Sending $NUM_TXS x 1 NOWA to randomly generated addresses"
echo ""

success=0
failed=0

# Generate addresses on the fly and send immediately
for i in $(seq 1 $NUM_TXS); do
    # Generate random 20-byte hex for address
    RAND_HEX=$(openssl rand -hex 20)
    
    # Convert to bech32 address using nowad
    TO_ADDR=$(nowad keys parse $RAND_HEX --output json 2>/dev/null | jq -r '.formats[0]' 2>/dev/null)
    
    # If that doesn't work, use debug addr
    if [ -z "$TO_ADDR" ] || [ "$TO_ADDR" == "null" ]; then
        # Use the simple prefix + encoding
        TO_ADDR="nowa1$(echo $RAND_HEX | head -c 39)"
    fi
    
    # Send transaction
    TX=$(nowad tx bank send $FROM_KEY $TO_ADDR $AMOUNT \
        --chain-id $CHAIN_ID \
        --node $NODE \
        --keyring-backend test \
        --gas 200000 \
        --gas-prices 0atest \
        --yes \
        --broadcast-mode async \
        2>&1)
    
    if echo "$TX" | grep -qi "txhash"; then
        ((success++))
        echo -ne "\r✅ Sent: $success | ❌ Failed: $failed | Progress: $i/$NUM_TXS"
    else
        ((failed++))
        echo -ne "\r✅ Sent: $success | ❌ Failed: $failed | Progress: $i/$NUM_TXS"
    fi
done

echo ""
echo ""
echo "🎉 Done!"
echo "📊 Results: ✅ $success succeeded, ❌ $failed failed"
