import           Lib
import           Test.Hspec

main :: IO ()
main =
  hspec $ do
    testMembersFromWorld
    testMembersFromWorldWithListify
    testListMossalcadiaMania
    testSummonAllGroupsInKumamotoCastle
    testAppendWorldForData
    testAllNothing
