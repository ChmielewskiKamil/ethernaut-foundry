#!/bin/zsh
# please note that this script uses zsh syntax
# it won't work in plain bash without some fixes

deployToAnvil() {
    # public key from available anvil accounts list
    read "account?Insert public key: "

    # the name of the contract you want to interact with
    # for example Fallback or CoinFlip
    read "contractName?Insert contract name: "

    # step 1 - Deploy ethernaut
    forge create Ethernaut --unlocked --from $account

    # step 2 - save ethernaut deployment address
    read "ethernautAddress?Please copy the 'deployed to' address: "
    echo $ethernaut

    # step 3 - deploy the factory
    # step 3.1 - we need to combine the level name with the word Factory
    levelFactoryName=$contractName"Factory"

    forge create $levelFactoryName --unlocked --from $account

}

deployToAnvil