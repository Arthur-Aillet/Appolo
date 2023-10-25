{-
-- EPITECH PROJECT, 2023
-- glados
-- File description:
-- AST
-}

module Ast.Type (Ast (..), Function (..), Structure (..), Operation (..), Type (..), Definition (..), Operable (..)) where

import Eval.Atom (Atom)
import Eval.Builtins (Operator)

data Function = Function [(String, Type)] (Maybe Type) Ast

data Definition
  = FuncDefinition String Function -- define a function
  | VarDefinition String Type -- define a variable

data Structure -- layout, structure and connection of statements, having no value
{- Useless? -}
  = Resolved -- expression resolving to no value
  | Return Operable
  | If Operable Ast Ast -- branching condition (if (x) {} {})
  | Single Ast -- single operation or operable ({x})
  | Block [Ast] [String] -- several actions ordered by variable precedence ({x;y})
  | Sequence [Ast] -- several actions ordered by precedence ({x >> y})
  deriving (Show, Eq)

data Operation -- statement involving an action, resulting in a value
  = Interrupt String -- Interrupt program flow
  | CallStd Operator [Operable] -- call a standard or operator operation (x(y))
  | CallFunc String [Operable] -- call a function, exposes both inherent IOPipes (x(y))
  | CallSH String [Operable] -- syscall of Operator program ($x(y)), exposes both IOPipes
  | Pipe Operable Operable -- stdout mapped to stdin ({x.y}, {x <- y})
  deriving (Show, Eq)

data Operable -- statement having a value
  = OpVariable String -- Variable reffering to single known value
  | OpValue Atom -- Single known value
  | OpOperation Operation -- operation resulting in an operable value
  | OpIOPipe String -- named pipe, String is likely a placeholder
  deriving (Show, Eq)

data Type
  = TypeBool
  | TypeChar
  | TypeInt
  | TypeFloat
  deriving (Show, Eq)

data Ast
  = AstStructure Structure -- structure block ({})
  | AstOperation Operation -- take an action
  deriving (Show, Eq)
