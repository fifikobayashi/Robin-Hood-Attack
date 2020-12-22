# Robin Hood Attack

For educational purposes, here's a contract that executes:

1. A DAI/sUSD batch flashloan on Aave V2
2. Uses DAI batch to short the smart contract security of Project X by buying up hack insurance from Cover Protocol
3. Uses sUSD batch to 'interact' with Project X
4. Repays the flash loan using gains from 'interacting' with Project X
5. Now just sit back and wait for the insurance payout from Cover Protocol
6. Then you can philanthropically return surplus 'interaction' funds back to Project X
7. Ask Project X for grey hat bounty

Note:
- Any references to existing projects are for demonstration purposes only
- Probably more efficient if this is flashmint powered
- Don't try and run this in prod, I left out a few things

An end to end atomic execution of this contract looks [like this on kovan](https://kovan.etherscan.io/tx/0xf82fbf1a79c12175aecf904422df35c430d5c12e71b4a44c0536c6d614a8ec4f).

![](https://github.com/fifikobayashi/Robin-Hood-Attack/blob/main/execution.PNG)
