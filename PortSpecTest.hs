module Main (main) where

import Control.Monad (forM_)
import PortSpec (parsePortSpec)
import System.Exit (exitFailure)

main :: IO ()
main = do
  forM_ cases $ \(input, expected) ->
    case parsePortSpec input of
      actual
        | actual == expected -> pure ()
        | otherwise -> do
            putStrLn ("PortSpec.hs failed for " ++ show input ++ ": " ++ show actual)
            exitFailure
  putStrLn "Haskell port parser checks passed"
  where
    cases =
      [ ("80", Just [80])
      , ("22-24", Just [22, 23, 24])
      , ("22,80,443,3306", Just [22, 80, 443, 3306])
      , ("80,22,80,22-23", Just [22, 23, 80])
      , (" 22 - 24 , 80 ", Just [22, 23, 24, 80])
      , ("1-65535", Just [1 .. 65535])
      , ("0-10", Nothing)
      , ("65536", Nothing)
      , ("24-22", Nothing)
      , ("80,,443", Nothing)
      , ("", Nothing)
      ]
