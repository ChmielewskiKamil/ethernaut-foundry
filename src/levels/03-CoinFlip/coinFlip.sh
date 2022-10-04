#!/bin/zsh
coinFlip() {
    # get the latest block number
    blockNumber=$(cast block latest number)
    # get the hash of the previous block
    blockhash=$(cast block $(($blockNumber - 1)) hash)
    
    FACTOR=57896044618658097711785492504343953926634992332820282019728792003956564819968

    # this is a hardcoded value to prove the point 
    # check out readme for details
    # blockhash=0xe0983ed68afd2bbaa2af9d58a1a1510aad6443d7eda671c5f880dbb1b92baa91
    echo ${blockhash}

    # calculate block value the same way as flip() function
    blockValue=$(cast --to-base --base-in hex ${blockhash} dec)
    echo ${blockValue}

    # this is a hardcoded value to prove the point 
    # check out readme for details
    #blockValue=101587072528837317882290343063414294045596843671841809291302363498692324600465

    # calculate the game outcome -> floating point number
    gameOutcome=$(bc <<< "scale=3; $blockValue / $FACTOR")
    echo ${gameOutcome}
}

coinFlip

# FACTOR
# IN DECIMAL:
# 5.78960446186581e+76
# IN HEX:
# 0x8000000000000000000000000000000000000000000000000000000000000000

# MAX UINT
# IN DECIMAL:
# 1.157920892373162e+77
# IN HEX:
# 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff

# EXAMPLE PROBLEMATIC BLOCK HASH
# IN DECIMAL:
# 1.0158707252883731e+77
# IN HEX:
# 0xe0983ed68afd2bbaa2af9d58a1a1510aad6443d7eda671c5f880dbb1b92baa91
# BUT FOUNDRY RETURNS:
# IN DECIMAL:
# 1.4205016708478877e+76
# which is completely wrong number
# it makes it so that the factor is always bigger than the blockValue
# and we will never receive number greater than 1