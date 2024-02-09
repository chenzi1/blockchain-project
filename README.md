Compile & Deploy

StudentToken.sol
StudentContract.sol
SchoolBalloting.sol

Showcase flows (individual students have one unique account address)
1. Mint token by admin(MOE) -> transfer to students address (eligible phase)
2. Register student without registration token -> revert transaction
3. Register student for ballot -> pay token to contract
4. Register student again -> transaction revert (student already registered)
5. Edit Registration -> existing records should be updated
6. Withdraw Registration -> can cancel registration and refund token
7. Start Allocation -> get students assigned to schools
8. Ballot completed -> store result to student registration result contract -> student query result from student registration result contract

Using Remix VM (Shanghai)

| account                                    | nric      | nric hash                                                          | school choice | residential address | isSingaporeCitizen |
|--------------------------------------------|-----------|--------------------------------------------------------------------|---------------|---------------------|--------------------|
| 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2 | S1234567A | 0xded8af907adb3643df2490d59d1713f2a162e15864220503fdc6441e2b114ee7 | 1             | Ang Mo Kio ave 1    | true               |
| 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db | S2345678B | 0x884d6ac059bb413aaf2615f1814068c4df63a1acf9be03b5eaef4da152a78465 | 1             | Bishan street 2     | false              |
| 0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB | S3456789C | 0x140dec86d6d2f3685be356e5dbf61614f65d07e4e217d5080c3c4bf9bf562f1c | 1             | Clementi ave 3      | true               |
| 0x617F2E2fD72FD9D5503197092aC168c91465E7f2 | S4567890D | 0x5828087607c4922db31a5b30e572c78f8712b24aeca4d147bc63b418a6fd9761 | 1             | Downtown street 4   | true               |
| 0x17F6AD8Ef982297579C203069C1DbfFE4348c372 | S5678901E | 0x8a3f43cb5fd152bad3600f108ad57ee2446969cababa1551548aabc0406b4508 | 1             | Expo ave 5          | true               |
| 0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678 | S6789012F | 0x3b4900250ee421a9b9bdfe56c4af6d6f701b0d216a9118fa7042f1d266ca43b5 | 2             | Farmland road 6     | true               |
| 0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7 | S7890123G | 0x21ddbcc1c717696304739789e041223ebb036fd9972529b33a98aff9276bb253 | 2             | Gardens street 7    | true               |
| 0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C | S8901234H | 0x36fd927bf44e88d267e7ba4ab05145b9230e67460f731f4a95b2c06eb1b571c8 | 2             | Holland ave 8       | true               |
| 0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC | S9012345I | 0x60d83018e412fbecfe8ae03a3c7c064cca567e52f1ab953554708abcebb6546b | 2             | Island road 9       | true               |
| 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c | S9876543J | 0x3f6eaf1713ae409e593994d51f197eea80dbba62f01dd0accd017fc66a75259e | 2             | Jurong street 10    | true               |

| school id | school name              | vacancies |
|-----------|--------------------------|-----------|
| 1         | Sunshine Primary School  | 4         |
| 2         | Moonlight Primary School | 3         |