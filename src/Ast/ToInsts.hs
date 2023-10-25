{-
-- EPITECH PROJECT, 2023
-- glados
-- File description:
-- AST To Insts
-}

module Ast.ToInsts (module Ast.ToInsts) where

import Ast.Type
  ( Ast (..),
    Definition (..),
    Function (..),
    Operable (..),
    Operation (CallFunc, CallStd),
    Structure (..),
    Type (TypeInt),
  )

import Ast.Context (Index(..), Context(..), LocalContext(..), createCtx, createLocalContext)

import Eval.Atom (Atom (AtomI))
import Eval.Builtins (operatorArgCount)
import Data.HashMap.Lazy (empty, (!?))
import Ast.Utils ((++++))

import Eval.Exec
import Eval.Builtins
import Eval.Instructions

data Binary = Binary Env Func deriving (Show)

createGcd :: Definition
createGcd =
  FuncDefinition
    "gcd"
    ( Function
        [("x", TypeInt), ("y", TypeInt)]
        (Just TypeInt)
        ( AstStructure
            ( If
                (OpOperation $ CallStd Eq [OpValue (AtomI 0), OpVariable "y"])
                (AstStructure $ Return $ OpVariable "x")
                ( AstStructure $
                    Return $
                      OpOperation $
                        CallFunc
                          "gcd"
                          [OpVariable "y", OpOperation (CallStd Division [OpVariable "x", OpVariable "y"])]
                )
            )
        )
    )

toInsts :: [Definition] -> Either String Binary
toInsts defs = case createCtx defs (Context empty) 0 of
  Left str -> Left str
  Right ctx -> convAllFunc defs (Binary [] []) ctx

convAllFunc :: [Definition] -> Binary -> Context -> Either String Binary
convAllFunc ((FuncDefinition "main" func) : xs) (Binary env []) ctx = case convFunc func ctx of
  Left err -> Left err
  Right func -> convAllFunc xs (Binary env func) ctx
convAllFunc ((VarDefinition _ _) : _) _ _ = Left "Error: Global Variables not supported yet"
convAllFunc ((FuncDefinition _ (Function args y z)) : xs) (Binary env funcs) ctx = case convFunc (Function args y z) ctx of
  Left err -> Left err
  Right func -> convAllFunc xs (Binary (env ++ [(length args, func)]) funcs) ctx
convAllFunc [] bin _ = Right bin

convFunc :: Function -> Context -> Either String Insts
convFunc (Function args output ast) ctx = case createLocalContext args output of
  Left err -> Left err
  Right local -> convAst ast ctx local

convStruct :: Structure -> Context -> LocalContext -> Either String Insts
convStruct Resolved _ _ = Left "Err: Resolved unsupported"
convStruct (Return ope) c l = case convOperable ope c l of
  Left err -> Left err
  Right insts -> Right $ insts ++ [Ret]
convStruct (If op ast_then ast_else) c l =
  concatInner
    [convOperable op c l,
    Right [JumpIfFalse (length then_insts)],
    then_insts,
    convAst ast_else c l]
  where
    then_insts = convAst ast_then c l
convStruct (Single ast) _ _ = Left "Err: Single unsupported"
convStruct (Block asts vars) _ _ = Left "Err: Block unsupported"
convStruct (Sequence asts) _ _ = Left "Err: Sequence unsupported"

convOperable :: Operable -> Context -> LocalContext -> Either String Insts
convOperable (OpValue val) c l = Right [PushD val]
convOperable (OpVariable name) c (LocalContext hash _) = case hash !? name of
  Nothing -> Left $ "Variable: " ++ name ++ " never defined"
  Just (Index index, _) -> Right [PushI index]
convOperable (OpOperation op) c l = convOperation op c l
convOperable (OpIOPipe op) _ _ = Left "Err: OpIOPipe unsupported"

concatInner :: [Either a [b]] -> Either a [b]
concatInner = foldl (\a b -> (++) <$> a <*> b) (Right [])

convOperation :: Operation -> Context -> LocalContext -> Either String Insts
convOperation (CallStd builtin ops) c l =
  if length ops == operatorArgCount builtin
    then (++) <$> concatInner (map (\op -> convOperable op c l) ops) <*> Right [Op builtin]
    else Left "Err: Invalid number of args"


--  <$> (\op -> (\a -> a ++ [Op builtin]) <$> convOperable op c l) ops
convOperation a _ _ = Left $ "Err: Operation unsupported" ++ show a


{-
= Interrupt String -- Interrupt program flow
\| CallStd String [Operable] -- call a standard or builtin operation (x(y))
\| CallFunc String [Operable] -- call a function, exposes both inherent IOPipes (x(y))
\| CallSH String [Operable] -- syscall of builtin program ($x(y)), exposes both IOPipes
\| Pipe Operable Operable -- stdout mapped to stdin ({x.y}, {x <- y})
-}
convAst :: Ast -> Context -> LocalContext -> Either String Insts
convAst (AstStructure struct) = convStruct struct
convAst (AstOperation op) = convOperation op
