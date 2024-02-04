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
7. Start ballot -> get students assigned -> assign result to student contract
8. Ballot completed -> student query result from student contract