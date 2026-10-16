{-# LANGUAGE ForeignFunctionInterface #-}

module PortSpec (hs_parse_port_spec, parsePortSpec) where

import Control.Applicative ((<|>))
import Control.Monad (guard)
import Data.Char (isDigit)
import Data.List (sort)
import Data.Word (Word16)
import Foreign.C.String (CString, peekCString)
import Foreign.C.Types (CInt(..))
import Foreign.Marshal.Array (pokeArray)
import Foreign.Ptr (Ptr, nullPtr)
import Foreign.Storable (poke)
import Text.ParserCombinators.ReadP
import Text.Read (readMaybe)

data PortTarget = Single Int | Range Int Int
  deriving (Eq, Show)

intParser :: ReadP Int
intParser = do
  digits <- munch1 isDigit
  case readMaybe digits of
    Just port | port >= 1 && port <= 65535 -> pure port
    _ -> pfail

rangeParser :: ReadP PortTarget
rangeParser = do
  start <- intParser
  skipSpaces
  _ <- char '-'
  skipSpaces
  end <- intParser
  guard (start <= end)
  pure (Range start end)

singleParser :: ReadP PortTarget
singleParser = Single <$> intParser

portParser :: ReadP PortTarget
portParser = rangeParser <|> singleParser

portSpecParser :: ReadP [PortTarget]
portSpecParser =
  skipSpaces *> sepBy1 portParser (skipSpaces *> char ',' <* skipSpaces)
    <* skipSpaces
    <* eof

expandTarget :: PortTarget -> [Int]
expandTarget (Single port) = [port]
expandTarget (Range start end) = [start .. end]

dedupeSorted :: Eq a => [a] -> [a]
dedupeSorted [] = []
dedupeSorted (port : ports) = port : dedupeSorted (dropWhile (== port) ports)

parsePortSpec :: String -> Maybe [Word16]
parsePortSpec input =
  case [targets | (targets, "") <- readP_to_S portSpecParser input] of
    [] -> Nothing
    parses ->
      Just
        ( map fromIntegral
            (dedupeSorted (sort (concatMap expandTarget (last parses))))
        )

hs_parse_port_spec :: CString -> Ptr Word16 -> CInt -> Ptr CInt -> IO CInt
hs_parse_port_spec input output capacity countOutput
  | input == nullPtr || output == nullPtr || countOutput == nullPtr =
      pure (-1)
  | capacity <= 0 = do
      poke countOutput 0
      pure (-1)
  | otherwise = do
      spec <- peekCString input
      case parsePortSpec spec of
        Nothing -> do
          poke countOutput 0
          pure (-1)
        Just ports
          | length ports > fromIntegral capacity -> do
              poke countOutput 0
              pure (-1)
          | otherwise -> do
              pokeArray output ports
              poke countOutput (fromIntegral (length ports))
              pure 0

foreign export ccall hs_parse_port_spec
  :: CString -> Ptr Word16 -> CInt -> Ptr CInt -> IO CInt
