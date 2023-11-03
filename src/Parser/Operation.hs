--
-- EPITECH PROJECT, 2023
-- apollo
-- File description:
-- Condition
--

module Parser.Operation (module Parser.Operation) where

import Ast.Type (Operable (..), Operation (..))
import Control.Applicative (Alternative ((<|>)))
import Eval.Operator (Operator (..))
import Parser.Char (parseClosingParenthesis, parseOpeningParenthesis, parseChar, parseClosingBraquet)
import Parser.Range (Range (..))
import Debug.Trace
import Parser.StackTrace (StackTrace (..), defaultLocation)
import Parser.Symbol (parseSymbol)
import Parser.Syntax (parseMany, parseWithSpace, parseMaybeparenthesis)
import Parser.Type (Parser (..))
import {-# SOURCE #-} Parser.Operable (parseOperable, parseDefinitionName)

-- Operator
--   = Add
--   | Incr
--   | Sub
--   | Decr
--   | Mul
--   | Div
--   | Mod
--   | Eq
--   | Lt
--   | LEt
--   | Gt
--   | GEt
--   | NEq
--   | And
--   | Or
--   | Not
--   | Print
--   | Concat
--   | Get
--   | Len

getPredicat :: String -> Maybe Operator
getPredicat "+" = Just Add
getPredicat "-" = Just Sub
getPredicat "*" = Just Mul
getPredicat "/" = Just Div
getPredicat "%" = Just Mod
getPredicat "==" = Just Eq
getPredicat "<" = Just Lt
getPredicat "<=" = Just LEt
getPredicat ">" = Just Gt
getPredicat ">=" = Just GEt
getPredicat "!=" = Just NEq
getPredicat "&&" = Just And
getPredicat "||" = Just Or
getPredicat ":" = Just Concat
getPredicat _ = Nothing

parsePredicat :: Parser String
parsePredicat = parseSymbol "+"
            <|> parseSymbol "-"
            <|> parseSymbol "*"
            <|> parseSymbol "/"
            <|> parseSymbol "%"
            <|> parseSymbol "=="
            <|> parseSymbol "<"
            <|> parseSymbol "<="
            <|> parseSymbol ">"
            <|> parseSymbol ">="
            <|> parseSymbol "!="
            <|> parseSymbol "&&"
            <|> parseSymbol "||"
            <|> parseSymbol ":"

---------------------------------------------

getUnary :: String -> Maybe Operator
getUnary "++" = Just Incr
getUnary "--" = Just Decr
getUnary "!" = Just Not
getUnary _ = Nothing

parseUnary :: Parser String
parseUnary =  parseSymbol "++"
          <|> parseSymbol "--"
          <|> parseSymbol "!"

---------------------------------------------

getIndex :: String -> Maybe Operator
getIndex "[" = Just Get
getIndex _ = Nothing

parseIndex :: Parser String
parseIndex = parseSymbol "["

---------------------------------------------

getBuiltin :: String -> Maybe Operator
getBuiltin "print" = Just Print
getBuiltin "len" = Just Len
getBuiltin _ = Nothing

parseBuiltin :: Parser String
parseBuiltin =  parseSymbol "print"
            <|> parseSymbol "len"

---------------------------------------------

checkOperator :: Parser String -> (String -> Maybe Operator) -> Parser Operator
checkOperator parser getter = Parser $ \s p -> case runParser parser s p of
  Right (operatorstr, str, pos) -> case getter operatorstr of
    Just a -> Right (a, str, pos)
    Nothing -> Left (StackTrace [("Invalid operator : \"" ++ operatorstr ++ "\"", Range p pos, defaultLocation)])
  Left a -> Left a

---------------------------------------------

parseStd :: Parser Operation
parseStd = Parser $ \s p -> case runParser (parseMaybeparenthesis parseOperable) s p of
  Right (resultLeft, newstrmiddle, newposmiddle) -> case runParser (parseWithSpace $ checkOperator parsePredicat getPredicat) newstrmiddle newposmiddle of
    Right (resultmiddle, newstrright, newposright) -> case runParser (parseMaybeparenthesis parseOperable) newstrright newposright of
      Right (resultright, newstr, newpos) -> Right (CallStd resultmiddle [resultLeft, resultright], newstr, newpos)
      Left a -> Left a
    Left a -> Left a
  Left a -> Left a

parseUnaryOp :: Parser Operation
parseUnaryOp = Parser $ \s p -> case runParser (parseWithSpace $ checkOperator parseUnary getUnary) s p of
  Right (resultLeft, newstrright, newposright) -> case runParser (parseMaybeparenthesis parseOperable) newstrright newposright of
    Right (resultright, newstr, newpos) -> Right (CallStd resultLeft [resultright], newstr, newpos)
    Left a -> Left a
  Left a -> Left a

parseIndexOp :: Parser Operation
parseIndexOp =  Parser $ \s p -> case runParser (parseMaybeparenthesis parseOperable) s p of
  Right (resultLeft, newstrmiddle, newposmiddle) -> case runParser (parseWithSpace $ checkOperator parseIndex getIndex) newstrmiddle newposmiddle of
    Right (resultmiddle, newstrright, newposright) -> case runParser (parseMaybeparenthesis parseOperable <* parseClosingBraquet) newstrright newposright of
      Right (resultright, newstr, newpos) -> Right (CallStd resultmiddle [resultLeft, resultright], newstr, newpos)
      Left a -> Left a
    Left a -> Left a
  Left a -> Left a

parseBuiltinFct :: Parser Operation
parseBuiltinFct = trace "aa" $  Parser $ \s p -> case runParser (parseWithSpace $ checkOperator parseBuiltin getBuiltin) s p of
  Right (fct, fctstr, fctpos) -> case runParser (parseMaybeparenthesis parseOperable)  fctstr fctpos of
    Right (op, opstr, oppos) -> Right (CallStd fct [op], opstr, oppos)
    Left a -> Left a
  Left a -> Left a

---------------------------------------------

parseargWithComa :: Parser Operable
parseargWithComa = parseWithSpace (parseChar ',') *> parseOperable

parseargs :: Parser [Operable]
parseargs =
  parseOpeningParenthesis *> parseMany ( parseWithSpace parseOperable <|> parseWithSpace parseargWithComa) <* parseClosingParenthesis

parseNoargs :: Parser [Operable]
parseNoargs = Parser $ \s p -> Right ([], s, p)

parseFct :: Parser Operation
parseFct = Parser $ \s p -> case runParser (parseWithSpace(parseSymbol"@" *> parseDefinitionName)) s p of
  Right (name, nstr, npos) -> case runParser (parseargs <|> parseNoargs) nstr npos of
    Right (args, astr, apos) -> Right (CallFunc name args, astr, apos)
    Left a -> Left a
  Left a -> Left a

parseSh :: Parser Operation
parseSh = Parser $ \s p -> case runParser (parseWithSpace(parseSymbol"$" *> parseDefinitionName)) s p of
  Right (name, nstr, npos) -> case runParser (parseargs <|> parseNoargs) nstr npos of
    Right (args, astr, apos) -> Right (CallSH name args, astr, apos)
    Left a -> Left a
  Left a -> Left a

parseCall :: Parser Operation
parseCall = parseFct
        <|> parseSh

---------------------------------------------

parseOperation :: Parser Operation
parseOperation = parseStd
              <|> parseUnaryOp
              <|> parseIndexOp
              <|> parseBuiltinFct
