module Text.Parse exposing (QueryTerm(..), parse)

{-| The `parse` function accepts a query string and if successful produces a value of
type `Ok QueryTerm`. If it is unsuccessful, it returns `Err` "ill-formed query".
For example, the query string "foo -bar | x y" yields the QueryTerm

    Disjunction
        [ Conjunction [ Word "foo", NotWord "bar" ]
        , Conjunction [ Word "x", Word "y" ]
        ]

@docs QueryTerm, parse

-}

import Parser exposing ((|.), (|=), Parser)
import Text.Library.ParserTools exposing (first, manySeparatedBy, text)


{-|

    Type of the parser syntax tree.

-}
type QueryTerm
    = Word String
    | NotWord String
    | Conjunction (List QueryTerm)
    | Disjunction (List QueryTerm)


{-| -}
parse : String -> Result String QueryTerm
parse input =
    case Parser.run disjunction input of
        Ok t ->
            Ok t

        Err _ ->
            Err "ill-formed query"


disjunction : Parser QueryTerm
disjunction =
    Parser.succeed identity
        |= (manySeparatedBy (Parser.symbol "| ") conjunction |> Parser.map Disjunction)
        |. Parser.end


conjunction : Parser QueryTerm
conjunction =
    manySeparatedBy Parser.spaces term |> Parser.map Conjunction



-- many term |> Parser.map Conjunction


{-|

    > run word "foo"
      Ok (Word "foo") : Result (List DeadEnd) API.Term

    > run word "-bar"
      Ok (NotWord "bar")

-}
term : Parser QueryTerm
term =
    Parser.oneOf [ wordWithSpaces, negativeWordWithSpaces, positiveWord, negativeWord ]


{-|

    > run positiveWord "foo bar"
      Ok (Word "foo") : Result (List DeadEnd) API.Term

-}
positiveWord : Parser QueryTerm
positiveWord =
    first
        (text (\c -> Char.isAlphaNum c) (\c -> c /= ' ') |> Parser.map .content |> Parser.map Word)
        Parser.spaces


wordWithSpaces : Parser QueryTerm
wordWithSpaces =
    (Parser.succeed (\start end source -> String.slice start (end - 1) source)
        |. Parser.symbol "'"
        |= Parser.getOffset
        |. Parser.chompUntil "'"
        |. Parser.symbol "'"
        |= Parser.getOffset
        |= Parser.getSource
        |. Parser.spaces
    )
        |> Parser.map Word


negativeWordWithSpaces : Parser QueryTerm
negativeWordWithSpaces =
    (Parser.succeed (\start end source -> String.slice start (end - 1) source)
        |. Parser.symbol "-'"
        |= Parser.getOffset
        |. Parser.chompUntilEndOr "'"
        |. Parser.symbol "'"
        |= Parser.getOffset
        |= Parser.getSource
        |. Parser.spaces
    )
        |> Parser.map NotWord


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
