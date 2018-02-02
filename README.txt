NOTES:
Steps to run website
Requires 3 terminal windows
WINDOW 1 (initialize local block chain)
  1. initialize ganache-cli or testrpc in terminal(this creates the test accounts that you can use to test functionalities)
      upon creation the terminal will output a mnemonic pertaining to the test users that you just created
        Note: you can execute these commands with tag "--port PORT#" to specify port
  2. sign out of metamask
  3. sign in to metamask using the mnemonic given from step 1
        note: 10 test accounts are created in step 1. although metamask only displays that there is 1 account you can add all 10
        by clicking create account (accounts will automatically be added sequentially)
  4. Keep this terminal open
WINDOW 2 (serve website on localhost)
  1. navigate to project folder
  2. "npm run dev" (note: yo can specify port the same way as window 1 -- THIS PORT SHOULD BE DIFFERENT FROM WINDOW 1)
WINDOW 3 (Run truffle actions -- compile, migrate, deploy)
  1. navigate to project folder
  2. "truffle compile" (or "truffle.cmd compile" for windows) -- compiles all .sol files in /contracts
  3. "truffle migrate" (or "truffle.cmd compile" for windows) -- migrates contracts to served website
        --note: check the truffle.js file and make sure the port number aligns with port number in step 1


Steps to run truffle test
  1. navigate to project
  2. "truffle develop" (or "truffle.cmd develop" for windows)
          note: this starts a truffle session that you can execute truffle commands without writting "truffle"
          i.e. "truffle test" --> "test"

Additional notes:
- If testing on server, make sure to deploy relevant contracts (see /migrations) 
- Only test files (JS) in the test folder will be executed with the command "truffle test"
- tests are written in JS and utilize the Chai Assertion Library http://chaijs.com/api/
    1. Check out documentation for basic testing
    2. the general idea is you use
      it("description of what you're testing", function() { test function })
    3. At checkpoints in the it-function, use assert() to ensure certain values. (its pretty self-explanatory, see /test/sharebeetoken.js for examples)
      --note: There are two ways to organize tests: there are examples of both in the current test file
                  1. using async and await keywords to mandate ordered execution of code
                    --benefits: very readable/easy to follow
                  2. use promises -- check out docs:https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise
                    --benefits: has a catch functionality that doesnt stop execution of code
                    (if executing restricted functionality in a solidity file, like something that should be required(), the whole test fails)
