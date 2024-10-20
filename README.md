# qclient scripts
qclient scripts to simplify coin operations

## pre-requisites
* qclient should be in the folder with `.config` directory
* qclient should be in the working/current directory
* node should be running, connected to network and sync'ed

## assumptions
* qclient signature checks is not needed

## split coin into parts with value
Usage: `./split_coin_into_parts_with_value.sh <qclient_version> <coin_addr> <parts> <part_value>`

Example: `./split_coin_into_parts_with_value.sh 2.0.1-testnet 0x0533c4c10d2246e4a9fead69e57fef2d6a5ab8fe112ddcd7986590affed09d20 2 0.002500000000`

Points of attention:
* `<coin_addr>` value should **match** the `<parts> * <part_value>`, otherwise, the command will not produce any results

## merge all coins
Usage: `./merge_all_coins.sh <qclient_version>`

Example: `./merge_all_coins.sh 2.0.1-testnet`

## merge coins with value
Usage: `./merge_coins_with_value.sh <qclient_version> <coin_value>`

Example: `./merge_coins_with_value.sh 2.0.1-testnet 0.002500000000`

## send all coins to account
Usage: `./send_all_coins_to_account.sh <qclient_version> <account_addr>`

Example: `./send_all_coins_to_account.sh.sh 2.0.1-testnet 0x16aaeb3c6366dfd7b2e989668415f7b62fa67bd43a23b1e068112c445e285200`

## send coins with value to account
Usage: `./send_coins_with_value_to_account.sh <qclient_version> <account_addr> <coin_value>`

Example: `./send_coins_with_value_to_account.sh.sh 2.0.1-testnet 0x16aaeb3c6366dfd7b2e989668415f7b62fa67bd43a23b1e068112c445e285200 0.002500000000`
