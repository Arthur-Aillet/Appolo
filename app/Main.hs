module Main (main) where

import Ast.Compile (Binary (..))
import Ast.Display (compile)
import Ast.Error (Compile (..))
import Ast.Type
import Eval
import Eval.Exec
import Eval.Exec (Operator (Add, Or, Sub))
import PreProcess
import System.Environment
import System.Exit (ExitCode (ExitFailure), exitWith)
import Prelude

createAbs :: Definition
createAbs =
  FuncDefinition
    "abs"
    ( Function
        [("n", TypeInt)]
        (Just TypeInt)
        ( AstStructure
            ( If
                [ ( OpOperation $ CallStd Lt [OpVariable "n", OpValue (AtomI 0)],
                    AstStructure $ Return $ OpOperation $ CallStd Mul [OpVariable "n", OpValue (AtomI (-1))]
                  )
                ]
                (Just $ AstStructure $ Return $ OpVariable "n")
            )
        )
    )

createFib :: Definition
createFib =
  FuncDefinition
    "fib"
    ( Function
        [("n", TypeInt)]
        (Just TypeInt)
        ( AstStructure
            ( If
                [ ( OpOperation $ CallStd Eq [OpVariable "n", OpValue (AtomI 0)],
                    AstStructure $ Return $ OpValue (AtomI 0)
                  ),
                  ( OpOperation $ CallStd Eq [OpVariable "n", OpValue (AtomI 1)],
                    AstStructure $ Return $ OpValue (AtomI 1)
                  )
                ]
                ( Just $
                    AstStructure $
                      Return $
                        OpOperation $
                          CallStd
                            Add
                            [ OpOperation $ CallFunc "fib" [OpOperation $ CallStd Sub [OpVariable "n", OpValue (AtomI 1)]],
                              OpOperation $ CallFunc "fib" [OpOperation $ CallStd Sub [OpVariable "n", OpValue (AtomI 2)]]
                            ]
                )
            )
        )
    )

createSub :: Definition
createSub =
  FuncDefinition
    "sub"
    ( Function
        [("a", TypeInt), ("b", TypeInt)]
        (Just TypeInt)
        ( AstStructure $
            Return $
              OpOperation $
                CallStd
                  Sub
                  [ OpVariable "a",
                    OpVariable "b"
                  ]
        )
    )

createGcd :: Definition
createGcd =
  FuncDefinition
    "gcd"
    ( Function
        [("x", TypeInt), ("y", TypeInt)]
        (Just TypeInt)
        ( AstStructure
            ( If
                [ ( OpOperation $ CallStd Eq [OpValue (AtomI 0), OpVariable "y"],
                    AstStructure $ Return $ OpVariable "x"
                  )
                ]
                ( Just $
                    AstStructure $
                      Return $
                        OpOperation $
                          CallFunc
                            "gcd"
                            [OpVariable "y", OpOperation (CallStd Mod [OpVariable "x", OpVariable "y"])]
                )
            )
        )
    )

createFst :: Definition
createFst =
  FuncDefinition
    "main"
    ( Function
        []
        (Just TypeBool)
        ( AstStructure $
            Sequence
              [ AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"],
                AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"]
              ]
        )
    )

createSnd :: Definition
createSnd =
  FuncDefinition
    "main"
    ( Function
        []
        (Just TypeBool)
        ( AstStructure $
            Sequence
              [ AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"],
                AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"]
              ]
        )
    )

createMain :: Definition
createMain =
  FuncDefinition
    "main"
    ( Function
        []
        (Just TypeBool)
        ( AstStructure $
            Sequence
              [ AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"],
                AstStructure $ Return $ OpOperation $ CallStd Or [OpValue (AtomI 3), OpVariable "res"]
              ]
        )
    )

main :: IO ()
main = do
  args <- getArgs
  files <- readFiles args
  (Binary env main_f) <- compile [createMain, createFst, createSnd]
  result <- exec env [] main_f [] []
  case result of
    Left a -> putStrLn a
    Right a -> print a
