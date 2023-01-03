module TextSearch.Parse exposing (QueryTerm(..), parse)

{-| The `parse` function accepts a query string and if successful produces a value of
type `QueryTerm`. For example, the query string "foo -bar | x y" yields the QueryTerm

    Disjunction [ Conjunction [ Word "foo", NotWord "bar" ], Conjunction [ Word "x", Word "y" ] ]

@docs QueryTerm, parse

-}

import Parser exposing ((|.), (|=), Parser)
import TextSearch.Library.ParserTools exposing (first, manySeparatedBy, text)


{-|

    Type of the parser syntax tree.

-}
type QueryTerm
    = Word String
    | NotWord String
    | Conjunction (List QueryTerm)
    | Disjunction (List QueryTerm)


{-| -}
parse : String -> Result (List Parser.DeadEnd) QueryTerm
parse input =
    Parser.run disjunction input


conjunction : Parser QueryTerm
conjunction =
    manySeparatedBy Parser.spaces term |> Parser.map Conjunction


disjunction : Parser QueryTerm
disjunction =
    manySeparatedBy (Parser.symbol "| ") conjunction |> Parser.map Disjunction


{-|

    > run word "foo"
      Ok (Word "foo") : Result (List DeadEnd) API.Term

    > run word "-bar"
      Ok (NotWord "bar")

-}
term : Parser QueryTerm
term =
    Parser.oneOf [ positiveWord, negativeWord ]


{-|

    > run positiveWord "foo bar"
      Ok (Word "foo") : Result (List DeadEnd) API.Term

-}
positiveWord : Parser QueryTerm
positiveWord =
    first
        (text (\c -> Char.isAlphaNum c) (\c -> c /= ' ') |> Parser.map .content |> Parser.map Word)
        Parser.spaces


{-|

> run negativeWord "-foo"

     Ok (NotWord "foo") : Result (List DeadEnd) API.Term

-}
negativeWord : Parser QueryTerm
negativeWord =
    (Parser.succeed (\r -> r.content)
        |. Parser.symbol "-"
        |= text Char.isAlphaNum (\c -> c /= ' ')
        |. Parser.spaces
    )
        |> Parser.map NotWord