module SearchTest exposing (suite)

--- (SearchConfig(..), mySearch)

import Expect
import Test exposing (..)
import Text.Parse exposing (QueryTerm(..), parse)
import Text.Search as Search


suite : Test
suite =
    describe "API"
        [ test "parser with error (0)" <|
            \_ ->
                parse "!foo"
                    |> Expect.equal (Err "ill-formed query")
        , test "parser with error (1)" <|
            \_ ->
                parse "!foo -bar"
                    |> Expect.equal (Err "ill-formed query")
        , test "parser with error (2)" <|
            \_ ->
                parse "foo !"
                    |> Expect.equal (Err "ill-formed query")
        , test "parser with error (3)" <|
            \_ ->
                parse "foo ! bar"
                    |> Expect.equal (Err "ill-formed query")
        , test "parser (conjunction with negative term)" <|
            \_ ->
                parse "foo -bar"
                    |> Expect.equal (Ok (Disjunction [ Conjunction [ Word "foo", NotWord "bar" ] ]))
        , test "parser (disjunction with negative term)" <|
            \_ ->
                parse "foo -bar | x y"
                    |> Expect.equal (Ok (Disjunction [ Conjunction [ Word "foo", NotWord "bar" ], Conjunction [ Word "x", Word "y" ] ]))
        , test "simple match (positive)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "bar" "foo bar"
                    |> Expect.equal (Ok True)
        , test "simple match (negative)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "baz" "foo bar"
                    |> Expect.equal (Ok False)
        , test "conjunctive match (positive)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "foo bar" "foo bar baz"
                    |> Expect.equal (Ok True)
        , test "conjunctive match (negative)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "foo alpha" "foo bar baz"
                    |> Expect.equal (Ok False)
        , test "conjunctive match with negation (positive)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "foo -fa" "foo bar baz"
                    |> Expect.equal (Ok True)
        , test "conjunctive match with negation (negative)" <|
            \_ ->
                Search.matchWithQueryStringToResult identity Search.NotCaseSensitive "foo -bar" "foo bar baz"
                    |> Expect.equal (Ok False)
        , test "simple search" <|
            \_ ->
                Search.withQueryStringToResult identity Search.NotCaseSensitive "abc" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal (Ok [ "abc def", "xyz abc  pqr" ])
        , test "conjunctive search" <|
            \_ ->
                Search.withQueryStringToResult identity Search.NotCaseSensitive "abc xyz" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal (Ok [ "xyz abc  pqr" ])
        , test "conjunctive search with negation" <|
            \_ ->
                Search.withQueryStringToResult identity Search.NotCaseSensitive "abc -xyz" [ "abc def", "def xyz", "xyz abc  pqr" ]
                    |> Expect.equal (Ok [ "abc def" ])
        , test "disjunctive search with negation" <|
            \_ ->
                Search.withQueryStringToResult identity Search.NotCaseSensitive "abc -xyz | pqr" [ "abc def", "def xyz", "xyz abc pqr" ]
                    |> Expect.equal (Ok [ "abc def", "xyz abc pqr" ])
        ]
