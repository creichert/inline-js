{-# LANGUAGE ApplicativeDo #-}
{-# LANGUAGE DeriveFunctor #-}
{-# LANGUAGE StrictData #-}

module Language.JavaScript.Inline.Internals.Parser
  ( Chunk(..)
  , parseChunksIO
  ) where

import Data.Functor
import Data.Void
import Text.Megaparsec
import Text.Megaparsec.Char
import UnliftIO (throwIO)

data Chunk a
  = LitChunk String
  | QuotedChunk a
  deriving (Functor, Show)

type Parser = Parsec Void String

parseQuotedChunk :: Parser String
parseQuotedChunk = do
  void $ char '$'
  c <- between (char '(') (char ')') $ takeWhile1P Nothing (/= ')')
  pure c

parseChunks :: Parser [Chunk String]
parseChunks =
  (do x <- try (Right <$> parseQuotedChunk) <|> Left <$> anyChar
      cs <- parseChunks
      pure $
        case x of
          Left c ->
            case cs of
              LitChunk c':cs' -> LitChunk (c : c') : cs'
              _ -> LitChunk [c] : cs
          Right c -> QuotedChunk c : cs) <|>
  pure []

parseChunksIO :: String -> IO [Chunk String]
parseChunksIO s =
  case runParser parseChunks "" s of
    Left err -> throwIO err
    Right r -> pure r
